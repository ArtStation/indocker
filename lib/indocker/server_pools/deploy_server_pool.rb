class Indocker::ServerPools::DeployServerPool
  def initialize(configuration:, logger:)
    @logger = logger
    @configuration = configuration

    @connections = configuration.servers.map do |server|
      Indocker::ServerPools::DeployServerConnection.new(
        logger: @logger,
        configuration: configuration,
        server: server,
      )
    end
  end

  def create_sessions!
    @connections.each(&:create_session!)
  end

  # NOTE: get is a bad name here, because we create a new connection.
  # TODO: why we create a new connection here?
  def get(server)
    connection = Indocker::ServerPools::DeployServerConnection.new(
      logger: @logger,
      configuration: @configuration,
      server: server,
    )
    connection.create_session!
    connection
  end

  def each(&proc)
    @connections.each(&proc)
  end

  def close_sessions
    @connections.each(&:close_session)
  end
end