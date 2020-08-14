class Indocker::ServerPools::DeployServerPool
  def initialize(configuration:, logger:)
    @logger = logger
    @configuration = configuration
    @connections = []
    @semaphore = Mutex.new
  end

  def create_connection!(server)
    @semaphore.synchronize do
      create_connection_unsafe!(server)
    end
  end

  def each(&proc)
    @connections.each(&proc)
  end

  def close_sessions
    @connections.each(&:close_session)
  end

  private
    def create_connection_unsafe!(server)
      connection = @connections.detect do |connection|
        connection.server.host == server.host &&
        connection.server.port == server.port &&
        connection.server.user == server.user
      end
      if connection.nil?
        connection = Indocker::ServerPools::DeployServerConnection.new(
          logger: @logger,
          configuration: @configuration,
          server: server,
        )
        connection.create_session!
        @connections.push(connection)
      end
      connection
    end
end