class Indocker::Configurations::ConfigurationBuilder
  attr_reader :repositories
  attr_reader :registries
  attr_reader :servers
  attr_reader :build_servers
  attr_reader :volumes
  attr_reader :networks
  attr_reader :env_files
  attr_reader :configuration

  def initialize(repositories:, name:, registries:, servers:, build_servers:, volumes:, networks:, env_files:, containers:)
    @repositories = repositories
    @registries = registries
    @servers = servers
    @volumes = volumes
    @networks = networks
    @build_servers = build_servers
    @env_files = env_files
    @containers = containers
    @configuration = Indocker::Configurations::Configuration.new(name)
  end

  def use_repository(name, as:)
    repository = @repositories.detect do |repo|
      repo.name == name
    end

    if !repository
      raise ArgumentError.new("repository :#{name} was not found")
    end

    @configuration.set_repository(as, repository)

    self
  end

  def confirm_deployment
    @configuration.set_confirm_deployment(true)
    self
  end

  def artifacts(server_artifacts)
    if !server_artifacts.is_a?(Hash)
      Indocker.logger.error("artifacts should be a hash for configuration :#{@configuration.name}")
      exit 1
    end

    server_artifacts.each do |artifact_name, server_names|
      artifact = Indocker.artifacts.detect do |a|
        a.name == artifact_name
      end

      if !artifact
        Indocker.logger.error("artifact :#{artifact_name} was not found")
        exit 1
      end

      if @configuration.servers.empty?
        Indocker.logger.error("artifacts should go after enabled_containers section")
        exit 1
      end

      servers = @configuration.servers.select do |s|
        server_names.include?(s.name)
      end

      servers += @configuration.build_servers.select do |s|
        server_names.include?(s.name)
      end

      extra_servers = server_names - servers.map(&:name)

      if !extra_servers.empty?
        Indocker.logger.error("invalid servers #{extra_servers.inspect} provided for artifact :#{artifact_name}")
        exit 1
      end

      @configuration.set_artifact_servers(artifact, servers)
    end

    self
  end

  def use_registry(name, as:)
    registry = @registries.detect do |r|
      r.repository_name == name
    end

    if !registry
      raise ArgumentError.new("registry :#{name} was not found")
    end

    @configuration.set_registry(as, registry)

    self
  end

  def use_env_file(name, as:)
    env_file = @env_files.detect do |ef|
      ef.name == name
    end

    if !env_file
      raise ArgumentError.new("env_file :#{name} was not found")
    end

    @configuration.set_env_file(as, env_file)

    self
  end

  def use_build_server(name)
    build_server = @build_servers.detect do |bs|
      bs.name == name
    end

    if !build_server
      raise ArgumentError.new("build_server :#{name} was not found")
    end

    @configuration.add_build_server(build_server)

    self
  end

  def enabled_containers(container_list)
    containers = container_list.keys
    extra_containers = containers - Indocker.container_files.keys

    if !extra_containers.empty?
      Indocker.logger.error("unrecognised containers: #{extra_containers.inspect} for configuration :#{Indocker.configuration.name}")
      exit 1
    end

    containers.each do |name|
      path = Indocker.container_files.fetch(name) do
        Indocker.logger.error("invalid container name :#{name} provided in enabled containers for configuration :#{@configuration.name}")
      end

      require path
    end

    @configuration.set_enabled_containers(containers.map(&:to_sym))

    container_list.each do |container_name, opts|
      if !opts.is_a?(Hash)
        Indocker.logger.error("container options should be a Hash for :#{container_name} in configuration :#{@configuration.name}")
        exit 1
      end

      count = opts[:scale] || 1

      if count <= 0
        raise ArgumentError.new("count should be > 0")
      end

      container = @configuration.containers.detect {|c| c.name == container_name}

      builder = Indocker::Containers::ContainerBuilder
        .new(name: container.name, configuration: @configuration, container: container)

      builder.scale(count)

      if opts[:build_args]
        builder.build_args(opts[:build_args])
      end

      if opts[:start]
        builder.start(opts[:start])
      end

      if opts[:redeploy_schedule]
        builder.redeploy_schedule(opts[:redeploy_schedule])
      end

      if !opts[:servers] && !opts[:servers_from]
        Indocker.logger.error("servers or servers_from should be defined for container :#{container_name} in configuration :#{@configuration.name}")
        exit 1
      end

      servers = recursively_fetch_servers(container_list, container_name)
      builder.servers(*servers)
    end

    self
  end

  def scale(opts)
    opts.each do |container_name, count|
      if count <= 0
        raise ArgumentError.new("count should be > 0")
      end

      container = @containers.detect {|c| c.name == container_name}

      if !container
        Indocker.logger.error("container :#{name} is not presented in enabled containers for configuration :#{@configuration.name}")
      end

      Indocker::Containers::ContainerBuilder
        .new(name: container.name, configuration: @configuration, container: container)
        .scale(count)
    end
  end

  def global_build_args(hash)
    @configuration.set_global_build_args(hash)
    self
  end

  private

  def recursively_fetch_servers(container_list, container_name)
    opts = container_list.fetch(container_name) do
      Indocker.logger.error("container :#{container_name} is not presented in enabled containers for configuration :#{@configuration.name}")
      exit 1
    end

    if !opts[:servers] && !opts[:servers_from]
      Indocker.logger.error("servers or servers_from should be defined for container :#{container_name} in configuration :#{@configuration.name}")
      exit 1
    end

    servers = if opts[:servers_from]
      if !opts[:servers_from].is_a?(Array)
        Indocker.logger.error("servers_from should be Array[Symbol] for container :#{container_name} in configuration :#{@configuration.name}")
        exit 1
      end

      opts[:servers_from].map do |name|
        recursively_fetch_servers(container_list, name)
      end.flatten
    else
      []
    end

    servers += if opts[:servers]
      if !opts[:servers].is_a?(Array)
        Indocker.logger.error("servers should be Array[Symbol] for container :#{container_name} in configuration :#{@configuration.name}")
        exit 1
      end

      opts[:servers]
    else
      []
    end

    servers.uniq
  end
end