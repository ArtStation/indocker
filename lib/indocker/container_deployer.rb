class Indocker::ContainerDeployer
  attr_reader :server_pool

  def initialize(configuration:, logger:)
    @configuration = configuration
    @logger = logger

    @server_pool = Indocker::ServerPools::DeployServerPool.new(
      configuration: @configuration,
      logger: logger
    )

    @deployed_containers = Hash.new(false)
    @deployed_servers = {}
  end

  def deploy(container, force_restart, skip_force_restart, progress)
    return if @deployed_containers[container]

    # Deploy the same container to all of its servers in parallel.
    #
    # Each thread opens its OWN ssh connection (create_connection!), so no
    # net-ssh session is shared between threads. We join all threads before
    # returning, so container dependency ordering (depends_on) is preserved:
    # a dependent container never starts deploying until every server of its
    # dependency has finished.
    threads = container.servers.map do |server|
      progress.start_deploying_container(container, server)

      Thread.new do
        deploy_to_server(container, server, force_restart, skip_force_restart, progress)
      end
    end

    results = threads.map(&:value)

    if results.any? { |exit_code| exit_code != 0 }
      exit 1
    end

    @deployed_containers[container] = true
  end

  def close_sessions
    @server_pool.close_sessions
  rescue => e
    @logger.error("error during closing sessions #{e.inspect}")
  end

  private

  # Runs a single container deployment on a single server. Returns the remote
  # exit code (0 on success). Runs inside its own thread with a dedicated ssh
  # connection, so it must not touch shared mutable state except the
  # thread-safe `progress`.
  def deploy_to_server(container, server, force_restart, skip_force_restart, progress)
    deploy_server = @server_pool.create_connection!(server)
    @logger.info("Deploying container: #{container.name.to_s.green} to #{server.user}@#{server.host}")

    result = deploy_server
      .run_container_remotely(
        configuration_name: Indocker.configuration_name,
        container_name:     container.name,
        force_restart:      force_restart && !skip_force_restart.include?(container.name)
      )

    if result.exit_code == 0
      @logger.info("Container deployment to #{server.user}@#{server.host} finished: #{container.name.to_s.green}")
      progress.finish_deploying_container(container, server)
    end

    deploy_server.close_session

    result.exit_code
  end
end