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

  def get(server)
    Indocker::DeployContext.new(
      logger: @logger,
      configuration: @configuration,
      server: server,
    )
  end

  def each(&proc)
    @contexts.each(&proc)
  end

  def close_sessions
    @contexts.each(&:close_session)
  end
end