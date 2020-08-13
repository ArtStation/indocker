class Indocker::Launchers::ContainerRunner
  def initialize(logger)
    @logger = logger
  end

  def run(configuration:, container_name:, force_restart:)
    path = Indocker.container_files.fetch(container_name) do
      @logger.error("container #{container_name} was not found in configuration #{configuration.name}")
      exit 1
    end

    require path

    deploy_context = Indocker::DeployContext.new(
      logger: @logger,
      configuration: configuration
    )

    container = configuration.containers.detect { |c| c.name == container_name }
    deploy_context.deploy(container, force_restart)
  end
end