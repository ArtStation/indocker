require 'thread'

class Indocker::DeploymentProgress
  def initialize(logger)
    @logger = logger

    if logger
      @logger.formatter = Proc.new do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
    end

    @progress = Hash.new(:waiting)
    @semaphore = Mutex.new

    @synced_binaries = {
      # Structure:
      # server => {
      #   start: time,
      #   finish: time,
      #   state: (:waiting|:in_progress|:finished)
      # }
    }

    @synced_env_files = {
      # Structure:
      # env_file => {
      #   server => {
      #     start: time,
      #     finish: time,
      #     state: (:waiting|:in_progress|:finished)
      #   }
      # }
    }

    @synced_artifacts = {
      # Structure:
      # artifact => {
      #   server => {
      #     start: time,
      #     finish: time,
      #     state: (:waiting|:in_progress|:finished)
      #   }
      # }
    }

    @synced_repositories = {
      # Structure:
      # repository => {
      #   server => {
      #     start: time,
      #     finish: time,
      #     state: (:waiting|:in_progress|:finished)
      #   }
      # }
    }

    @deployed_containers = {
      # Structure:
      # container => {
      #   server => {
      #     build_start: time,
      #     build_finish: time,
      #     deploy_start: time,
      #     deploy_finish: time,
      #     state: (:waiting|:building|:waiting_deployment|:deploying|:finished)
      #   }
      # }
    }
  end

  def setup(binaries_servers:, build_servers:, deploy_servers:, env_files:, artifact_servers:,
            repositories:, force_restart:, skip_build:, skip_deploy:, containers:)
    @force_restart = force_restart
    @skip_build    = skip_build
    @skip_deploy   = skip_deploy

    binaries_servers.each do |server|
      @synced_binaries[server] = {
        start: nil,
        finish: nil,
        state: :waiting
      }
    end

    repositories.each do |repository|
      @synced_repositories[repository] = {}

      build_servers.each do |server|
        @synced_repositories[repository][server] = {
          start: nil,
          finish: nil,
          state: :waiting
        }
      end
    end

    env_files.each do |env_file|
      @synced_env_files[env_file] = {}

      deploy_servers.each do |server|
        @synced_env_files[env_file][server] = {
          start: nil,
          finish: nil,
          state: :waiting
        }
      end
    end

    artifact_servers.each do |artifact, servers|
      @synced_artifacts[artifact] = {}

      servers.each do |server|
        @synced_artifacts[artifact][server] = {
          start: nil,
          finish: nil,
          state: :waiting
        }
      end
    end

    @containers = containers

    containers.each do |container|
      @deployed_containers[container] = {}

      container.servers.each do |server|
        @deployed_containers[container][server] = {
          build_start: nil,
          build_finish: nil,
          deploy_start: nil,
          deploy_finish: nil,
          state: :waiting
        }
      end
    end

    log
  end

  def start_syncing_binaries(server)
    @semaphore.synchronize do
      @synced_binaries[server][:start] = Time.now
      @synced_binaries[server][:state] = :in_progress
      log
    end
  end

  def finish_syncing_binaries(server)
    @semaphore.synchronize do
      @synced_binaries[server][:finish] = Time.now
      @synced_binaries[server][:state] = :finished
      log
    end
  end

  def start_syncing_env_file(server, env_file)
    @semaphore.synchronize do
      @synced_env_files[env_file][server][:start] = Time.now
      log
    end
  end

  def finish_syncing_env_file(server, env_file)
    @semaphore.synchronize do
      @synced_env_files[env_file][server][:finish] = Time.now
      @synced_env_files[env_file][server][:state] = :finished
      log
    end
  end

  def start_syncing_artifact(server, artifact)
    @semaphore.synchronize do
      @synced_artifacts[artifact][server][:start] = Time.now
      log
    end
  end

  def finish_syncing_artifact(server, artifact)
    @semaphore.synchronize do
      @synced_artifacts[artifact][server][:finish] = Time.now
      @synced_artifacts[artifact][server][:state] = :finished
      log
    end
  end

  def start_syncing_repository(server, repository)
    @semaphore.synchronize do
      @synced_repositories[repository][server][:start] = Time.now
      log
    end
  end

  def finish_syncing_repository(server, repository)
    @semaphore.synchronize do
      @synced_repositories[repository][server][:finish] = Time.now
      @synced_repositories[repository][server][:state] = :finished
      log
    end
  end

  def start_building_container(container)
    @semaphore.synchronize do
      time = Time.now

      @deployed_containers[container].each do |server, data|
        next if data[:build_start]
        data[:build_start] = time
        data[:state] = :building
      end

      log
    end
  end

  def finish_building_container(container)
    @semaphore.synchronize do
      time = Time.now

      @deployed_containers[container].each do |server, data|
        next if data[:build_finish]
        data[:build_finish] = time
        data[:state] = :waiting_deployment
      end

      log
    end
  end

  def start_deploying_container(container, server)
    @semaphore.synchronize do
      @deployed_containers[container][server][:deploy_start] = Time.now
      @deployed_containers[container][server][:state] = :deploying
      log
    end
  end

  def finish_deploying_container(container, server)
    @semaphore.synchronize do
      @deployed_containers[container][server][:deploy_finish] = Time.now
      @deployed_containers[container][server][:state] = :finished
      log
    end
  end

  def log
    return if !@logger
    system("clear")

    if @skip_build
      @logger.info("Warning: Image build is skipped for all containers".purple)
    end

    if @skip_deploy
      @logger.info("Warning: All container deployment is skipped".purple)
    end

    if @force_restart
      @logger.info("Warning: All containers will be force restarted".purple)
    end

    # BINARIES formatter
    synced_binaries_servers = []
    not_synced_binaries_servers = []

    @synced_binaries.each do |server, data|
      if data[:state] == :finished
        synced_binaries_servers << server
      else
        not_synced_binaries_servers << server
      end
    end

    if !synced_binaries_servers.empty?
      @logger.info("Binaries synced:".green)

      synced_binaries_servers.each do |server|
        data = @synced_binaries[server]
        total = ", total: #{(data[:finish] - data[:start]).round}s" if data[:finish]
        @logger.info("  - #{server.name.to_s.yellow}#{total}")
      end
    end

    if !not_synced_binaries_servers.empty?
      @logger.info("Binaries syncing:".green)

      not_synced_binaries_servers.each do |server|
        data = @synced_binaries[server]
        @logger.info("  - #{server.name.to_s.cyan} (#{data[:state]}...)")
      end
    end

    # ENV FILES formatter
    synced_env_files = []
    not_synced_env_files = []

    @synced_env_files.each do |env_file, server_info|
      server_info.each do |server, data|
        if data[:state] == :finished
          if !synced_env_files.include?(env_file)
            synced_env_files << env_file
          end
        else
          if !not_synced_env_files.include?(env_file)
            not_synced_env_files << env_file
          end
        end
      end
    end

    if !synced_env_files.empty?
      @logger.info("ENV files synced:".green)

      synced_env_files.each do |env_file|
        servers_data = @synced_env_files[env_file]

        servers_data.each do |server, data|
          next if data[:state] != :finished
          total = ", total: #{(data[:finish] - data[:start]).round}s" if data[:finish]
          @logger.info("  - #{env_file.to_s.yellow}, server: #{server.name}#{total}")
        end
      end
    end

    if !not_synced_env_files.empty?
      @logger.info("ENV files syncing:".green)

      not_synced_env_files.each do |env_file|
        servers_data = @synced_env_files[env_file]

        servers_data.each do |server, data|
          next if data[:state] == :finished
          @logger.info("  - #{env_file.to_s.cyan}, server: #{server.name} (#{data[:state]}...)")
        end
      end
    end

    # Artifacts formatter
    synced_artifact = []
    not_synced_artifact = []

    @synced_artifacts.each do |artifact, server_info|
      server_info.each do |server, data|
        if data[:state] == :finished
          if !synced_artifact.include?(artifact)
            synced_artifact << artifact
          end
        else
          if !not_synced_artifact.include?(artifact)
            not_synced_artifact << artifact
          end
        end
      end
    end

    if !synced_artifact.empty?
      @logger.info("Artifacts synced:".green)

      synced_artifact.each do |artifact|
        servers_data = @synced_artifacts[artifact]

        servers_data.each do |server, data|
          next if data[:state] != :finished
          total = ", total: #{(data[:finish] - data[:start]).round}s" if data[:finish]
          @logger.info("  - #{artifact.name.to_s.yellow}, server: #{server.name}#{total}")
        end
      end
    end

    if !not_synced_artifact.empty?
      @logger.info("Artifacts syncing:".green)

      not_synced_artifact.each do |artifact|
        servers_data = @synced_artifacts[artifact]

        servers_data.each do |server, data|
          next if data[:state] == :finished
          @logger.info("  - #{artifact.name.to_s.cyan}, server: #{server.name} (#{data[:state]}...)")
        end
      end
    end

    # REPOSITORIES formatter
    synced_repositories = []
    not_synced_repositories = []

    @synced_repositories.each do |repository, server_info|
      server_info.each do |server, data|
        if data[:state] == :finished
          if !synced_repositories.include?(repository)
            synced_repositories << repository
          end
        else
          if !not_synced_repositories.include?(repository)
            not_synced_repositories << repository
          end
        end
      end
    end

    if !synced_repositories.empty?
      @logger.info("Repositories synced:".green)

      synced_repositories.each do |repository|
        servers_data = @synced_repositories[repository]

        servers_data.each do |server, data|
          next if data[:state] != :finished
          total = ", total: #{(data[:finish] - data[:start]).round}s" if data[:finish]
          @logger.info("  - #{repository.to_s.yellow}, server: #{server.name}#{total}")
        end
      end
    end

    if !not_synced_repositories.empty?
      @logger.info("Repositories syncing:".green)

      not_synced_repositories.each do |repository|
        servers_data = @synced_repositories[repository]

        servers_data.each do |server, data|
          next if data[:state] == :finished
          @logger.info("  - #{repository.to_s.cyan}, server: #{server.name} (#{data[:state]}...)")
        end
      end
    end

    # Containers formatter
    deployed_containers = []
    not_deployed_containers = []

    @deployed_containers.each do |container, server_info|
      server_info.each do |server, data|
        if data[:state] == :finished
          if !deployed_containers.include?(container)
            deployed_containers << container
          end
        else
          if !not_deployed_containers.include?(container)
            not_deployed_containers << container
          end
        end
      end
    end

    if !deployed_containers.empty?
      @logger.info("Deployed containers:".green)

      deployed_containers = deployed_containers
        .sort_by { |container|
          @deployed_containers[container]
            .map { |server, data| data[:deploy_finish] }
            .reject(&:nil?)
            .sort
            .last
            .to_i
        }

      deployed_containers.each do |container|
        servers_data = @deployed_containers[container]

        servers_data.each do |server, data|
          next if data[:state] != :finished
          total = ", total: #{(data[:deploy_finish] - data[:build_start]).round}s"
          build = ", build: #{(data[:build_finish] - data[:build_start]).round}s"
          deploy = ", deploy: #{(data[:deploy_finish] - data[:deploy_start]).round}s"
          @logger.info("  - #{container.name.to_s.yellow}, server: #{server.name}#{build}#{deploy}#{total}")
        end
      end
    end

    if !not_deployed_containers.empty?
      @logger.info("To be deployed containers:".green)

      not_deployed_containers.each do |container|
        servers_data = @deployed_containers[container]

        servers_data.each do |server, data|
          next if data[:state] == :finished

          name = container.name.to_s

          name = if data[:state] == :waiting
            name
          else
            name.cyan
          end

          @logger.info("  - #{name}, server: #{server.name} (#{data[:state]}...)")
        end
      end
    end
  end

  private

  def format_time(time)
    time.strftime("%H:%M:%S")
  end
end