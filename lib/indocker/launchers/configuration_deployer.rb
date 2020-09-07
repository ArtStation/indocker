require 'timeout'
require 'benchmark'
require 'tempfile'

class Indocker::Launchers::ConfigurationDeployer
  REMOTE_OPERATION_TIMEOUT = 60

  def initialize(logger:, global_logger:)
    Thread.abort_on_exception = true # abort all threads if exception occurs

    @logger = logger
    @global_logger = global_logger

    @progress = Indocker::DeploymentProgress.new(
      Indocker.logger.level == Logger::DEBUG ? nil : Logger.new(STDOUT)
    )
    @compiled_images = Hash.new(false)
  end

  # Launch deployment & measure the benchmark
  def run(configuration:, deployment_policy:)
    time = Benchmark.realtime do
      if deployment_policy.force_restart
        @logger.warn("WARNING. All containers will be forced to restart.")
      end

      if deployment_policy.skip_build
        @logger.warn("WARNING. Images build step will be skipped")
      end

      if deployment_policy.skip_deploy
        @logger.warn("WARNING. Images deploy step will be skipped")
      end

      run!(configuration: configuration, deployment_policy: deployment_policy)
    end

    @global_logger.info("Deployment finished".green)
    @global_logger.info("Total time taken: #{time.round}s".green)
  end

  # The main flow of the deployment would happen in this method.
  def run!(configuration:, deployment_policy:)
    containers = find_containers_to_deploy(configuration, deployment_policy)

    clonner = Indocker::Repositories::Clonner.new(configuration, @logger)
    build_server_pool = Indocker::ServerPools::BuildServerPool.new(configuration: configuration, logger: @logger)
    deployer = Indocker::ContainerDeployer.new(configuration: configuration, logger: @logger)

    @global_logger.info("Establishing ssh sessions to all servers...")
    build_server_pool.create_sessions!

    build_servers = configuration
      .build_servers
      .uniq { |s| s.host }

    deploy_servers = containers
      .map(&:servers)
      .flatten
      .uniq { |s| s.host }

    servers = (deploy_servers + build_servers).uniq { |s| s.host }

    @progress.setup(
      binaries_servers: servers,
      build_servers:    build_servers,
      deploy_servers:   deploy_servers,
      env_files:        configuration.env_files.keys,
      repositories:     configuration.repositories.keys,
      force_restart:    deployment_policy.force_restart,
      skip_build:       deployment_policy.skip_build,
      skip_deploy:      deployment_policy.skip_deploy,
      containers:       containers,
      artifact_servers: configuration.artifact_servers,
    )

    remote_operations = sync_indocker(servers)
    wait_remote_operations(remote_operations)

    remote_operations = sync_env_files(deploy_servers, configuration.env_files)
    wait_remote_operations(remote_operations)

    remote_operations = pull_repositories(clonner, build_servers, configuration.repositories)
    wait_remote_operations(remote_operations)

    remote_operations = sync_artifacts(clonner, configuration.artifact_servers)
    wait_remote_operations(remote_operations)

    update_crontab_redeploy_rules(configuration, build_servers.first)

    containers.uniq.each do |container|
      recursively_deploy_container(
        configuration,
        deployer,
        build_server_pool,
        container,
        containers,
        deployment_policy.skip_build,
        deployment_policy.skip_deploy,
        deployment_policy.force_restart,
        deployment_policy.skip_force_restart
      )
    end

    Thread
      .list
      .each { |t| t.join if t != Thread.current }
  ensure
    build_server_pool.close_sessions if build_server_pool
    deployer.close_sessions if deployer
  end

  private

  def wait_remote_operations(remote_operations)
    remote_operations.each do |remote_operation|
      begin
        Timeout::timeout(REMOTE_OPERATION_TIMEOUT) do
          remote_operation.thread.join
        end
      rescue Timeout::Error
        @global_logger.error("Deployment aborted. Remote operation :#{remote_operation.operation} on server #{remote_operation.server.user}@#{remote_operation.server.host} did not finish during #{REMOTE_OPERATION_TIMEOUT} seconds.")
        exit 1
      end
    end
  end

  def find_containers_to_deploy(configuration, deployment_policy)
    load_enabled_containers(configuration)

    containers = []

    deployment_policy.deploy_tags.each do |tag|
      containers += configuration.containers.select do |container|
        container.tags.include?(tag)
      end
    end

    deployment_policy.skip_containers.each do |name|
      container = configuration.containers.detect do |container|
        container.name == name
      end

      if !container
        @global_logger.error("Invalid --skip container :#{name} for configuration :#{configuration.name}")
        @global_logger.info("Available containers:")

        configuration.containers.sort_by(&:name).each do |container|
          @global_logger.info("  - #{container.name}")
        end

        exit 1
      end
    end

    deployment_policy.deploy_containers.each do |name|
      container = configuration.containers.detect do |container|
        container.name == name
      end

      if container
        containers.push(container)
      else
        @global_logger.error("container :#{name} was not found in configuration :#{configuration.name}")

        exit 1
      end
    end

    if deployment_policy.deploy_tags.empty? && deployment_policy.deploy_containers.empty?
      containers = configuration.containers.select do |container|
        configuration.enabled_containers.include?(container.name)
      end
    end

    if !deployment_policy.skip_dependent
      containers = collect_dependent_containers(containers)
    end

    if !deployment_policy.skip_dependent
      containers = collect_soft_dependent_containers(containers, configuration)
    end

    extra_containers = containers.map(&:name) - configuration.enabled_containers

    if !extra_containers.empty?
      @global_logger.warn("configuration :#{configuration.name} does not include following containers: #{extra_containers.inspect}")
      @global_logger.warn("they will be skipped during deployment")
    end

    containers = containers
      .select { |container| configuration.container_enabled?(container) }
      .select { |container| !deployment_policy.skip_containers.include?(container.name) }
      .select { |container|
        (deployment_policy.skip_tags & container.tags).empty?
      }

    if !deployment_policy.servers.empty?
      containers = containers.select {|c| !(c.servers.map(&:name) & deployment_policy.servers).empty? }
    end

    if containers.empty?
      @global_logger.error("at least one container should be specified for deployment")
      exit 1
    else
      @global_logger.info("Following containers will be deployed:")

      servers = deployment_policy.servers
      if servers.empty?
        servers = containers.map(&:servers).flatten.uniq.map(&:name)
      end

      servers.each do |server_name|
        @global_logger.info("")
        @global_logger.info("List of containers for server #{server_name.to_s.yellow}")

        containers.each do |container|
          if container.servers.map(&:name).include?(server_name)
            scale = container.get_start_option(:scale)
            scale_msg = scale > 1 ? "  (#{container.get_start_option(:scale)})" : ''
            @global_logger.info("  - #{container.name}#{scale_msg}")
          end
        end
      end

      if (deployment_policy.require_confirmation || configuration.confirm_deployment) && !deployment_policy.auto_confirm
        @global_logger.info("\n")
        @global_logger.info("Do you want to continue deployment? (y or n)")
        result = gets.chomp

        if result.downcase != 'y'
          @global_logger.info("Deployment aborted")
          exit 0
        end
      end

      containers.uniq {|c| c.name}
    end
  end

  def load_enabled_containers(configuration)
    configuration.enabled_containers.each do |container_name|
      path = Indocker.container_files[container_name]
      require path
    end
  end

  def collect_dependent_containers(containers)
    result = containers

    result += containers.map do |container|
      collect_dependent_containers(container.dependent_containers)
    end.flatten

    result.uniq
  end

  def collect_soft_dependent_containers(containers, configuration)
    result = containers

    soft_dependent_containers = containers
      .map(&:soft_dependent_containers)
      .flatten
      .uniq(&:name)

    result +=  soft_dependent_containers.select do |container|
      configuration.enabled_containers.include?(container.name) &&
        !Indocker.launched?(container.name)
    end

    result
  end

  def compile_image(configuration, image, build_server)
    return if @compiled_images[image]

    image.dependent_images.each do |dependent_image|
      next if @compiled_images[image]
      compile_image(configuration, dependent_image, build_server)
    end

    compiler = Indocker::Images::ImageCompiler.new

    @logger.info("Image compilation started #{image.name.to_s.green}")

    result = nil

    time = Benchmark.realtime do
      result = build_server
        .compile_image_remotely(
          configuration_name: Indocker.configuration_name,
          image_name:         image.name
        )
    end

    if result.exit_code != 0
      exit 1
    end

    @logger.info("Image compilation completed #{image.name.to_s.green}. Time taken: #{time}")

    @compiled_images[image] = true
  end

  def recursively_deploy_container(configuration, deployer, build_server_pool, container,
    containers, skip_build, skip_deploy, force_restart, skip_force_restart)

    container.dependent_containers.each do |container|
      recursively_deploy_container(
        configuration,
        deployer,
        build_server_pool,
        container,
        containers,
        skip_build,
        skip_deploy,
        force_restart,
        skip_force_restart
      )
    end

    return if !containers.include?(container)

    @progress.start_building_container(container)

    if !skip_build
      build_server = build_server_pool.get

      build_server.set_busy(true)
      compile_image(configuration, container.image, build_server)
      build_server.set_busy(false)
    end

    @progress.finish_building_container(container)

    if !skip_deploy
      deploy_container(deployer, container, force_restart, skip_force_restart)
    end
  end

  def deploy_container(deployer, container, force_restart, skip_force_restart)
    deployer.deploy(container, force_restart, skip_force_restart, @progress)
  end

  class RemoteOperation
    attr_reader :thread, :server, :operation, :message

    def initialize(thread, server, operation, message = nil)
      @thread = thread
      @server = server
      @operation = operation
      @message = message
    end
  end

  def pull_repositories(clonner, servers, repositories)
    @logger.info("Clonning/pulling repositories")

    remote_operations = []

    servers.each do |server|
      remote_operations += repositories.map do |alias_name, repository|
        @progress.start_syncing_repository(server, alias_name)

        thread = Thread.new do
          session = Indocker::SshSession.new(
            host: server.host,
            user: server.user,
            port: server.port,
            logger: @logger
          )

          if repository.is_local?
            @logger.info("Rsyncing repository :#{alias_name} from #{repository.root_path} to #{server.user}@#{server.host}:#{repository.clone_path}")

            Indocker::Rsync.sync(
              session,
              File.join(repository.root_path, '.'),
              repository.clone_path,
              create_path: repository.clone_path,
              raise_on_error: true
            )
          elsif repository.is_git?
            @logger.info("Pulling repository #{alias_name.to_s.green} for #{server.user}@#{server.host}")
            result = clonner.clone(session, repository)

            if result.exit_code != 0
              @logger.error("Repository :#{repository.name} was not clonned")
              @logger.error(result.stderr_data)
              exit 1
            end
          elsif repository.is_no_sync?
            @logger.info("Skipping pull/sync operation for no_sync repository :#{alias_name} #{repository.clone_path}")
          else
            raise NotImplementedError.new("unsupported repository type: #{repository.inspect}")
          end

          @progress.finish_syncing_repository(server, alias_name)
        end

        RemoteOperation.new(thread, server, :repository_pull)
      end
    end

    remote_operations
  end

  def sync_artifacts(clonner, artifact_servers)
    @logger.info("Syncing git artifacts")

    remote_operations = []

    artifact_servers.each do |artifact, servers|
      remote_operations += servers.map do |server|
        @progress.start_syncing_artifact(server, artifact)

        thread = Thread.new do
          server.synchronize do
            session = Indocker::SshSession.new(
              host: server.host,
              user: server.user,
              port: server.port,
              logger: @logger
            )

            if artifact.is_a?(Indocker::Artifacts::Git)
              @logger.info("Pulling git artifact  #{artifact.name.to_s.green} for #{server.user}@#{server.host}")
              result = clonner.clone(session, artifact.repository)

              if result.exit_code != 0
                @logger.error("Artifact repository :#{artifact.repository.name} was not clonned")
                @logger.error(result.stderr_data)
                exit 1
              end
            end

            if artifact.source_path.present? && artifact.target_path.present?
              @logger.warn("Deprecated: artifact #source_path and #target_path methods are deprecated. Use #files instead!")

              source_path = artifact.build_source_path(artifact_item.source_path)
              target_path = artifact.build_target_path(artifact_item.target_path)

              result = session.exec!("mkdir -p #{target_path}")
              result = session.exec!("cp -r #{source_path} #{target_path}")

              if !result.success?
                @logger.error(result.stdout_data)
                @logger.error(result.stderr_data)
                exit 1
              end
            end

            artifact.files.each do |artifact_item|
              source_path = artifact.build_source_path(artifact_item.source_path)
              target_path = artifact.build_target_path(artifact_item.target_path)

              result = session.exec!("mkdir -p #{target_path}")
              result = session.exec!("cp -r #{source_path} #{target_path}")

              if !result.success?
                @logger.error(result.stdout_data)
                @logger.error(result.stderr_data)
                exit 1
              end
            end

            @progress.finish_syncing_artifact(server, artifact)
          end
        end

        RemoteOperation.new(thread, server, :artifact_sync)
      end
    end

    remote_operations
  end

  def update_crontab_redeploy_rules(configuration, server)
    redeploy_containers = configuration.containers.select {|c| c.redeploy_schedule}.uniq
    return if redeploy_containers.empty?

    deploy_user       = "#{server.user}@#{server.host}"
    crontab_filepath  = Indocker.redeploy_crontab_path

    crontab = Indocker::CrontabRedeployRulesBuilder
      .new(
        configuration:  configuration,
        logger:         @logger,
      )
      .call(redeploy_containers)

    tmp_crontab_file = Tempfile.new('crontab')
    tmp_crontab_file.write(crontab)
    tmp_crontab_file.close

    @logger.info("Updating crontab file #{deploy_user}:#{crontab_filepath}")

    Indocker::Shell.command("scp #{tmp_crontab_file.path} #{deploy_user}:#{crontab_filepath}", @logger)

    tmp_crontab_file.unlink

    Indocker::Shell.command("ssh #{deploy_user} 'crontab #{crontab_filepath}'", @logger)
  end

  def sync_indocker(servers)
    servers.map do |server|
      @progress.start_syncing_binaries(server)

      thread = Thread.new do
        session = Indocker::SshSession.new(
          host: server.host,
          user: server.user,
          port: server.port,
          logger: @logger
        )

        sync_path = Indocker::IndockerHelper.indocker_dir
        @logger.info("Syncing indocker to #{server.user}@#{server.host}:#{sync_path}")

        Indocker::Rsync.sync(
          session,
          File.join(Indocker.root_dir, '.'),
          sync_path,
          create_path: sync_path,
          raise_on_error: true,
        )

        @progress.finish_syncing_binaries(server)
      end

      RemoteOperation.new(thread, server, :indocker_sync)
    end
  end

  def sync_env_files(servers, env_files)
    remote_operations = []

    servers.map do |server|
      remote_operations += env_files.map do |alias_name, env_file|
        @progress.start_syncing_env_file(server, alias_name)

        thread = Thread.new do
          if env_file.is_a?(Indocker::EnvFiles::Local)
            sync_path = File.join(Indocker.deploy_dir, 'env_files', File.basename(env_file.path))
            @logger.info("Syncing env file :#{alias_name} from #{env_file.path} to #{server.user}@#{server.host}:#{sync_path}")

            session = Indocker::SshSession.new(
              host: server.host,
              user: server.user,
              port: server.port,
              logger: @logger
            )

            session.exec!("mkdir -p #{Indocker::EnvFileHelper.folder}")

            Indocker::Rsync.sync(
              session,
              env_file.path,
              sync_path,
              raise_on_error: true
            )
          elsif env_file.is_a?(Indocker::EnvFiles::Remote)
            @logger.warn("Sync operation for remote env file :#{alias_name} is skipped")
          else
            @logger.error("unsupported env file type: #{env_file.inspect}")
            raise "unsupported env file type: #{env_file.inspect}"
          end

          @progress.finish_syncing_env_file(server, alias_name)
        end

        RemoteOperation.new(thread, server, :env_file_sync)
      end
    end

    remote_operations
  end
end
