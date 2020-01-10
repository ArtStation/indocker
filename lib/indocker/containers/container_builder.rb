class Indocker::Containers::ContainerBuilder
  attr_reader :container

  def initialize(name:, configuration:, container: nil)
    @container = container || Indocker::Containers::Container.new(name)
    @configuration = configuration
    configuration.add_container(@container)
  end

  def command(name)
    @container.set_start_command(name)
  end

  def build_args(opts)
    raise ArgumentError.new("build args should be a Hash") if !opts.is_a?(Hash)
    opts = Indocker::HashMerger.deep_merge(@container.build_args, opts) # merge with already defined args
    @container.set_build_args(opts)
    self
  end

  def tags(*tag_list)
    if !tag_list.is_a?(Array)
      tag_list = [tag_list]
    end

    @container.set_tags(tag_list)
    self
  end

  def image(name)
    path = Indocker.image_files[name]

    if !path
      raise ArgumentError.new("Image :#{name} was not found in bounded contexts folder")
    else
      require path
    end

    image = @configuration.images.detect do |image|
      image.name == name
    end

    if !image
      Indocker.logger.error("image :#{name} was not found in configuration :#{@configuration.name}")
      exit 1
    end

    @container.set_image(image)
    self
  end

  def servers(*server_list)
    server_list.uniq!

    extra_servers = server_list - Indocker.servers.map(&:name)

    if !extra_servers.empty?
      Indocker.logger.error("unrecognized servers #{extra_servers.inspect} for container :#{@container.name} in configuration :#{@configuration.name}")
      exit 1
    end

    servers = Indocker.servers.select {|s| server_list.include?(s.name)}
    @container.set_servers(servers)
    self
  end

  def networks(*network_list)
    network_list.uniq!

    networks = Indocker.networks.select do |network|
      network_list.include?(network.name)
    end

    extra_networks = network_list - networks.map(&:name)

    if !extra_networks.empty?
      raise ArgumentError.new("unknown networks: #{extra_networks.inspect} for container :#{@container.name}")
    end

    @container.set_networks(networks)
    self
  end

  def volumes(*volume_list)
    volume_list.uniq!

    volumes = Indocker.volumes.select do |volume|
      volume_list.include?(volume.name)
    end

    extra_volumes = volume_list - volumes.map(&:name)

    if !extra_volumes.empty?
      raise Indocker.logger.error("unknown volumes: #{extra_volumes.inspect} for container :#{@container.name}")
      exit 1
    end

    @container.set_volumes(volumes)
    self
  end

  def daemonize(flag)
    @container.daemonize(flag)
    self
  end

  def depends_on(*container_list)
    if !container_list.is_a?(Array)
      container_list = [container_list]
    end

    container_list.uniq!

    container_list.each do |name|
      path = Indocker.container_files.fetch(name) do
        Indocker.logger.error("Dependent container :#{name} was not found in bounded contexts dir for container :#{@container.name}")
        exit 1
      end

      require path
    end

    containers = @configuration.containers.select do |container|
      container_list.include?(container.name)
    end

    containers.each do |container|
      @container.add_dependent_container(container)
    end

    self
  end

  def soft_depends_on(*container_list)
    container_list = Array(container_list).uniq

    container_list.each do |name|
      path = Indocker.container_files.fetch(name) do
        Indocker.logger.error("Soft dependent container :#{name} was not found in bounded contexts dir for container :#{@container.name}")
        exit 1
      end

      require path
    end

    containers = @configuration.containers.select do |container|
      container_list.include?(container.name)
    end

    containers.each do |container|
      @container.add_soft_dependent_container(container)
    end

    self
  end

  def before_start(proc)
    container.set_before_start_proc(proc)
    self
  end

  def after_start(proc)
    container.set_after_start_proc(proc)
    self
  end

  def after_deploy(proc)
    container.set_after_deploy_proc(proc)
    self
  end

  def start(opts)
    opts = Indocker::HashMerger.deep_merge(container.start_options, opts)
    container.set_start_options(opts)
    self
  end

  def scale(number)
    container.set_scale(number)
  end

  def redeploy_schedule(schedule)
    container.set_redeploy_schedule(schedule)
    self
  end
end