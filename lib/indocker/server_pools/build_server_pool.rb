class Indocker::ServerPools::BuildServerPool
  def initialize(configuration:, logger:, global_logger:)
    @logger = logger
    @configuration = configuration
    @global_logger = global_logger

    @contexts = configuration.build_servers.map do |build_server|
      Indocker::BuildContext.new(
        logger: @logger,
        configuration: configuration,
        build_server: build_server,
        global_logger: @global_logger,
      )
    end
  end

  def create_sessions!
    @contexts.each(&:create_session!)
  end

  def get
    context = nil

    loop do
      context = @contexts.detect {|c| !c.busy?}
      sleep(0.1)
      break if context
    end

    context
  end

  def each(&proc)
    @contexts.each(&proc)
  end

  def close_sessions
    @contexts.each(&:close_session)
  rescue => e
    @logger.error("error during session close: #{e.inspect}")
  end
end