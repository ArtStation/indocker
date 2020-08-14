class Indocker::Launchers::ImagesCompiler
  def initialize(logger)
    @logger = logger
  end

  def compile(configuration:, image_list:, skip_dependent:)
    preload_images(configuration, image_list)

    build_context = Indocker::BuildContext.new(
      configuration: configuration,
      logger: @logger,
      global_logger: Indocker.global_logger
    )

    image_compiler = Indocker::Images::ImageCompiler.new

    image_list.each do |image_name|
      image = Indocker.configuration.images.detect do |i|
        i.name == image_name
      end

      image_compiler.compile(build_context, image, skip_dependent)
    end
  end

  private

  def preload_images(configuration, image_list)
    image_list.each do |image_name|
      image_path = Indocker.image_files.fetch(image_name) do
        @logger.error("image not found :#{image_name} in configuration :#{configuration.name}")
        exit 1
      end

      require image_path
    end
  end
end