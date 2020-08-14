require 'fileutils'

class Indocker::Images::ImageCompiler
  BUILDS_DIR = 'image_build'.freeze
  DOCKERIGNORE = <<~EOS
    Dockerfile
    .DS_Store
    **/.DS_Store
    **/*.log
    **/*_spec.rb
    node_modules
    .vagrant
    .vscode
    tmp
    logs
  EOS

  def initialize
    @compiled_images = Hash.new(false)
  end

  def compile(build_context, image, skip_dependent)
    if !skip_dependent
      image.dependent_images.each do |dependent_image|
        compile_image(build_context, dependent_image)
      end
    end

    compile_image(build_context, image)
  end

  def compile_image(build_context, image)
    return if @compiled_images[image]

    compile_dir = File.join(build_context.configuration.build_dir, BUILDS_DIR, image.name.to_s)
    FileUtils.rm_rf(compile_dir)
    FileUtils.mkdir_p(compile_dir)

    if image.build_context
      templates_compiler = Indocker::Images::TemplatesCompiler.new

      templates_compiler.compile(
        templates_dir: image.build_context,
        compile_dir: compile_dir,
        context: build_context
      )
    end

    compiler = Indocker::Images::TemplateCompiler.new

    target_dockerfile = File.join(compile_dir, 'Dockerfile')
    FileUtils.cp(image.dockerfile, target_dockerfile)
    compiler.compile(target_dockerfile, build_context)

    File
      .join(compile_dir, '.dockerignore')
      .tap { |_| File.write(_, Indocker.dockerignore.join("\n")) }

    if image.before_build
      image.before_build.call(build_context, compile_dir)
    end

    build_context.build_image(image, compile_dir)

    @compiled_images[image] = true
  end
end
