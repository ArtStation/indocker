class Indocker::Images::Image
  DOCKERFILE = "Dockerfile"

  attr_reader :name, :compile, :compile_rpaths, :dependent_images, :build_args

  def initialize(name)
    @compile = false
    @name = name
    @dependent_images = []
    @build_args = {}
  end

  def image_name
    "#{@name}_image"
  end

  def set_tag(tag)
    @tag = tag
  end

  def tag
    @tag || (raise ArgumentError.new("tag is not set for image :#{@name}"))
  end

  def set_build_args(opts)
    @build_args = opts
  end

  def set_registry(registry)
    @registry = registry
  end

  def registry
    @registry || (raise ArgumentError.new("registry is not set for image :#{@name}"))
  end

  def set_dockerfile(path)
    @dockerfile = path
  end

  def compile?(path)
    return true if path.include?(DOCKERFILE)
    return false if !@compile
    return true if @compile_rpaths.empty?
    return true if @compile_rpaths.any? { |rpath| path.include?(rpath) }
    return false
  end

  def set_compile(flag_or_rpaths)
    @compile_rpaths = []

    if flag_or_rpaths == false
      @compile = false
      return
    end

    @compile = true

    if flag_or_rpaths.is_a?(Array)
      @compile_rpaths = flag_or_rpaths
    end

    @dockerfile = path
  end

  def dockerfile
    @dockerfile || (raise ArgumentError.new("Dockerfile path is not set for image :#{@name}"))
  end

  def set_build_context(path)
    @build_context = path
  end

  def build_context
    @build_context
  end

  def set_before_build(proc)
    @before_build = proc
  end

  def before_build
    @before_build
  end

  def set_after_build(proc)
    @after_build = proc
  end

  def after_build
    @after_build
  end

  def registry_url
    url = if registry.is_local?
      File.join(registry.repository_name.to_s, image_name)
    else
      File.join(registry.url, registry.repository_name.to_s, image_name)
    end

    "#{url}:#{tag}"
  end

  def local_registry_url
    url = File.join(registry.repository_name.to_s, image_name)
    "#{url}:#{tag}"
  end

  def add_dependent_image(image)
    @dependent_images.push(image) if !@dependent_images.include?(image)
  end
end