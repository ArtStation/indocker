class Indocker::Configurations::Configuration
  attr_reader :name
  attr_reader :repositories
  attr_reader :registries
  attr_reader :build_servers
  attr_reader :global_build_args
  attr_reader :deploy_args
  attr_reader :images
  attr_reader :containers
  attr_reader :volumes
  attr_reader :networks
  attr_reader :env_files
  attr_reader :artifact_servers
  attr_reader :confirm_deployment

  def initialize(name)
    @name = name
    @repositories = {}
    @registries = {}
    @env_files = {}
    @build_servers = []
    @images = []
    @volumes = []
    @networks = []
    @containers = []
    @artifact_servers = {}
    @confirm_deployment = false
  end

  def servers
    @containers.map(&:servers).flatten.uniq
  end

  def set_artifact_servers(artifact, servers)
    @artifact_servers[artifact] = servers
  end

  def set_confirm_deployment(flag)
    @confirm_deployment = !!flag
  end

  def container(name)
    @containers.detect {|c| c.name == name}
  end

  def set_enabled_containers(list)
    @enabled_containers = list
  end

  def enabled_containers
    @enabled_containers || (raise ArgumentError.new("enabled container list was not specified in configuration"))
  end

  def container_enabled?(container)
    @enabled_containers.include?(container.name)
  end

  def set_repository(alias_name, repository)
    if @repositories.has_key?(alias_name)
      raise ArgumentError.new("alias name :#{alias_name} is already used by repository: #{@repositories[alias_name].inspect}")
    end

    @repositories[alias_name] = repository
  end

  def set_registry(alias_name, registry)
    if @registries.has_key?(alias_name)
      raise ArgumentError.new("alias name :#{alias_name} is already used by registry: #{@registries[alias_name].inspect}")
    end

    @registries[alias_name] = registry
  end

  def set_env_file(alias_name, env_file)
    if @env_files.has_key?(alias_name)
      raise ArgumentError.new("alias name :#{alias_name} is already used by env file: #{@env_files[alias_name].inspect}")
    end

    @env_files[alias_name] = env_file
  end

  def add_build_server(build_server)
    if !@build_servers.include?(build_server)
      @build_servers.push(build_server)
    end
  end

  def set_global_build_args(hash)
    @global_build_args = hash
  end

  def set_deploy_args(hash)
    @deploy_args = hash
  end

  def add_image(image)
    @images.push(image)
  end

  def add_container(container)
    @containers.push(container)
  end

  def next_build_server
    @current_position ||= 0
    build_server = @build_servers[@current_position]
    @current_position += 1

    if @current_position >= @build_servers.size - 1
      @current_position = 0
    end

    build_server
  end

  def build_dir
    "/tmp/#{@name}"
  end

  def hostname(container, number)
    Indocker::ContainerHelper.hostname(@name, container, number)
  end

  def get_binding
    binding
  end
end