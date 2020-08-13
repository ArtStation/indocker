class Indocker::ServerPools::BuildServerPool
  def initialize(configuration:, logger:)
    @logger = logger
    @configuration = configuration

    @connections = configuration.build_servers.map do |build_server|
      Indocker::ServerPools::BuildServerConnection.new(
        logger: @logger,
        configuration: configuration,
        server: build_server,
      )
    end
  end

  def create_sessions!
    @connections.each(&:create_session!)
  end

  def get
    context = nil

    loop do
      context = @connections.detect {|c| !c.busy?}
      sleep(0.1)
      break if context
    end

    context
  end

  def each(&proc)
    @connections.each(&proc)
  end

  def close_sessions
    @connections.each(&:close_session)
  rescue => e
    @logger.error("error during session close: #{e.inspect}")
  end
end