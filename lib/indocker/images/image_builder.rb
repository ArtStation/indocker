class Indocker::Images::ImageBuilder
  attr_reader :image

  def initialize(name:, configuration:, dir:)
    @configuration = configuration
    @image = Indocker::Images::Image.new(name)
    dockerfile = File.join(dir, 'Dockerfile')

    if File.exist?(dockerfile)
      @image.set_dockerfile(dockerfile)
    end

    build_context = File.join(dir, 'build_context')

    if Dir.exist?(build_context)
      @image.set_build_context(build_context)
    end

    @image.set_tag('latest')
    @configuration.add_image(@image)
  end

  def build_args(opts)
    @image.set_build_args(opts)
    self
  end

  def registry(name)
    registry = @configuration.registries.fetch(name) do
      raise ArgumentError.new("registry with alias name :#{name} is not defined in configuration :#{@configuration.name}")
    end

    @image.set_registry(registry)
    self
  end

  def dockerfile(path)
    if !File.exist?(path)
      raise ArgumentError.new("Dockerfile was not found in #{path}")
    end

    @image.set_dockerfile(path)
    self
  end

  def depends_on(*image_list)
    if !image_list.is_a?(Array)
      image_list = [image_list]
    end

    image_list.uniq!

    image_list.each do |name|
      path = Indocker.image_files.fetch(name) do
        Indocker.logger.error("Dependent image :#{name} was not found in bounded contexts dir for image :#{@image.name}")
        exit 1
      end

      require path
    end

    images = image_list.map do |image_sym|
      @configuration.images.detect do |i|
        i.name == image_sym
      end
    end

    images.each do |image|
      @image.add_dependent_image(image)
    end

    self
  end

  def tag(tag)
    @image.set_tag(tag)
    self
  end

  def build_context(path)
    if !File.directory?(path)
      raise ArgumentError.new("No directory found in #{path}")
    end

    @image.set_build_context(path)
    self
  end

  def before_build(proc)
    @image.set_before_build(proc)
    self
  end

  def after_build(proc)
    @image.set_after_build(proc)
    self
  end
end