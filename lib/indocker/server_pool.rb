class Indocker::ServerPool
  def initialize(configuration:, logger:)
    @logger = logger
    @configuration = configuration

    @contexts = configuration.servers.map do |server|
      Indocker::DeployContext.new(
        logger: @logger,
        configuration: configuration,
        server: server,
      )
    end
  end

  def create_sessions!
    @contexts.each(&:create_session!)
  end

  # NOTE: get is a bad name here, because we create a new connection.
  # TODO: why we create a new connection here?
  def get(server)
    context = Indocker::DeployContext.new(
      logger: @logger,
      configuration: @configuration,
      server: server,
    )
    context.create_session!
    context
  end

  def each(&proc)
    @contexts.each(&proc)
  end

  def close_sessions
    @contexts.each(&:close_session)
  end
end