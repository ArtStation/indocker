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

    @server_locks = {}
    @server_locks_mutex = Mutex.new
  end

  def deploy(container, force_restart, skip_force_restart, progress)
    return if @deployed_containers[container]

    # Deploy the container to all of its servers in parallel, each server in its
    # own thread with its own ssh connection.
    #
    # Per-server exclusion: only one container may deploy on a given server at a
    # time, so several container types don't spike CPU/memory by starting at once
    # on the same host. We grab the lock of every target server before deploying.
    # Locks are always taken in a consistent (sorted) order, so concurrent
    # deployments of containers with overlapping server sets can't deadlock.
    ordered_servers = container.servers.sort_by { |server| server_lock_key(server) }
    locks = ordered_servers.map { |server| server_lock(server) }.uniq

    with_locks(locks) do
      threads = container.servers.map do |server|
        Thread.new do
          deploy_to_server(container, server, force_restart, skip_force_restart, progress)
        end
      end

      results = threads.map(&:value)

      if results.any? { |exit_code| exit_code != 0 }
        exit 1
      end
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
    progress.start_deploying_container(container, server)

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

  def server_lock_key(server)
    [server.host, server.port, server.user]
  end

  # Returns a process-wide singleton Mutex for the given server, so the same lock
  # is shared across every container targeting that server.
  def server_lock(server)
    key = server_lock_key(server)

    @server_locks_mutex.synchronize do
      @server_locks[key] ||= Mutex.new
    end
  end

  def with_locks(locks, &block)
    if locks.empty?
      block.call
    else
      locks.first.synchronize { with_locks(locks.drop(1), &block) }
    end
  end
end
