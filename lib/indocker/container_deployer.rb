class Indocker::ContainerDeployer
  attr_reader :server_pool

  def initialize(configuration:, logger:)
    @configuration = configuration
    @logger = logger

    @server_pool = Indocker::ServerPool.new(
      configuration: @configuration,
      logger: logger
    )

    @deployed_containers = Hash.new(false)
    @deployed_servers = {}
  end

  def create_sessions!
    @server_pool.create_sessions!
  end

  def deploy(container, force_restart, skip_force_restart, progress)
    return if @deployed_containers[container]

    container.servers.each do |server|
      progress.start_deploying_container(container, server)

      exec_proc = if !container.is_daemonized?
        Proc.new do |&block|
          block.call
        end
      else
        Proc.new do |&block|
          Thread.new do
            block.call
          end
        end
      end

      exec_proc.call do
        deploy_context = @server_pool.get(server)
        @logger.info("Deploying container: #{container.name.to_s.green} to #{server.user}@#{server.host}")

        command_output  = @logger.debug? ? "" : " > /dev/null"
        debug_options   = @logger.debug? ? "-d" : ""

        if force_restart && !skip_force_restart.include?(container.name)
          force_restart_options = force_restart ? "-f" : ""
        end

        result = deploy_context
          .session
          .exec!(
            "cd #{Indocker::IndockerHelper.indocker_dir} && ./bin/remote/run -C #{Indocker.configuration_name} -c #{container.name} #{debug_options} #{command_output} #{force_restart_options}"
          )

        Indocker::SshResultLogger
          .new(@logger)
          .log(result, "#{container.name.to_s.green} deployment for server #{server.name} failed")

        exit 1 if result.exit_code != 0
        @logger.info("Container deployment to #{server.user}@#{server.host} finished: #{container.name.to_s.green}")

        deploy_context.close_session
        progress.finish_deploying_container(container, server)
      end
    end

    @deployed_containers[container] = true
  end

  def close_sessions
    @server_pool.close_sessions
  rescue => e
    @logger.error("error during closing sessions #{e.inspect}")
  end
end