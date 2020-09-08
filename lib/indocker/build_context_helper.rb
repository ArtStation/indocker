class Indocker::BuildContextHelper
  attr_reader :configuration, :build_server

  def initialize(configuration, build_server)
    @configuration = configuration
    @build_server = build_server
    @clonned_repositories = Hash.new(false)
  end

  def image_url(image_sym)
    path = Indocker.image_files.fetch(image_sym) do
      Indocker.logger.error("image :#{image_sym} was not found in configuration :#{@configuration.name}")
      exit 1
    end

    require path

    image = @configuration.images.detect do |i|
      i.name == image_sym
    end

    if image.nil?
      raise ArgumentError.new("image :#{image_sym} was not found in configuration")
    end

    image.registry_url
  end

  def repository_path(name)
    repo = repository(name)
    repo.clone_path
  end

  def repository(name)
    @configuration.repositories.fetch(name) do
      raise ArgumentError.new("repository :#{name} is not defined in configuration")
    end
  end

  def global_build_args
    @global_build_args = Indocker::ContextArgs.new(nil, @configuration.global_build_args, nil)
  end

  def container_enabled?(container)
    @configuration.enabled_containers.include?(container.name)
  end

  class Containers
    def initialize(configuration)
      @configuration = configuration
    end

    def method_missing(name, *args)
      if args.size > 0
        raise ArgumentError.new("containers.#{name} does not accept arguments")
      end

      if Indocker.container_files.has_key?(name)
        require Indocker.container_files.fetch(name)
      end

      container = @configuration.containers.detect do |container|
        container.name == name
      end

      if !container
        raise ArgumentError.new("container :#{name} was not found in configuration")
      end

      Container.new(@configuration, container)
    end
  end

  class Container
    def initialize(configuration, container)
      @configuration = configuration
      @container = container
    end

    def build_args
      Indocker::ContextArgs.new(
        nil,
        Indocker::HashMerger.deep_merge(@container.build_args, @container.image.build_args),
        nil,
        @container
      )
    end

    def hostname(number = nil)
      Indocker::ContainerHelper.hostname(@configuration.name, @container, number)
    end

    def count
      @container.get_start_option(:scale) || 1
    end

    def method_missing(name, *args)
      @container.send(name, *args)
    end
  end

  def containers
    @containers ||= Containers.new(@configuration)
  end

  def get_binding
    binding
  end
end