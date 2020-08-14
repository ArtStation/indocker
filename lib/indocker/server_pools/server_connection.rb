class Indocker::ServerPools::ServerConnection
  attr_reader :server, :session

  def initialize(logger:, configuration:, server:)
    @logger = logger
    @configuration = configuration
    @server = server
  end

  def create_session!
    return unless @server
    
    @session = Indocker::SshSession.new(
      host: @server.host,
      user: @server.user,
      port: @server.port,
      logger: @logger
    )
  end

  def exec!(command)
    @session.exec!(command)
  end

  def close_session
    @session.close if @session
  end

  def set_busy(flag)
    @busy = !!flag
  end

  def busy?
    !!@busy
  end
end