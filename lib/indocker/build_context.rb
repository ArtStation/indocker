require 'fileutils'

class Indocker::BuildContext
  attr_reader :session, :server, :configuration, :helper, :logger

  def initialize(configuration:, build_server:, logger:, global_logger:)
    @configuration = configuration
    @logger = logger
    @helper = Indocker::BuildContextHelper.new(@configuration, @build_server)
    @server = build_server
    @global_logger = global_logger
    @compiled_images = Hash.new(false)
  end

  def create_session!
    return unless @server

    @session = Indocker::SshSession.new(
      host: @server.host,
      user: @server.user,
      port: @server.port,
      logger: @logger
    )
  end

  def exec!(command)
    @session.exec!(command)
  end

  def close_session
    @session.close if @session
  end

  def image_compiled?(image)
    @compiled_images[image]
  end

  def set_busy(flag)
    @busy = !!flag
  end

  def busy?
    !!@busy
  end

  def set_compiled(image)
    @compiled_images[image] = true
  end

  def build_image(image, build_dir, args: [])
    image_name = image.image_name
    registry = image.registry
    tag        = image.tag

    FileUtils.cd(build_dir) do
      if @logger.debug?
        @logger.debug("#{"Docker image content:".yellow}")

        Dir[File.join(build_dir, '*')]
          .map {|path|
            file = path.gsub(build_dir, '')
            @logger.debug("  .#{file}".yellow)
          }
          .join("\n")
      end

      if !@logger.debug?
        args = args.push('-q')
      end

      build_args = args.join(' ')

      res = Indocker::Docker.build(image.local_registry_url, build_args)
      
      if res.exit_status != 0
        @global_logger.error("image compilation :#{image.name} failed")
        @global_logger.error(res.stdout)
        exit 1
      end

      Indocker::Docker.tag(image.local_registry_url, image.registry_url)
      Indocker::Docker.tag(image.local_registry_url, image.local_registry_url)

      if !image.registry.is_local?
        Indocker::Docker.push(image.registry_url)
      end
    end
  end
end