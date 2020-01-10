require 'erb'
require 'fileutils'

class Indocker::Images::TemplatesCompiler
  def compile(templates_dir:, compile_dir:, context:)
    prepare_dirs!(templates_dir, compile_dir)

    compiler = Indocker::Images::TemplateCompiler.new

    Dir[File.join(compile_dir, '**/**')].each do |file|
      next if !File.file?(file)
      compiler.compile(file, context)
    end
  end

  private

  def prepare_dirs!(templates_dir, compile_dir)
    Indocker.logger.debug("recreating directory #{compile_dir}".grey)
    FileUtils.rm_rf(compile_dir)
    FileUtils.mkdir_p(compile_dir)

    Indocker.logger.debug("copy template files".grey)
    Indocker.logger.debug("  from: #{templates_dir}".grey)
    Indocker.logger.debug("    to: #{compile_dir}".grey)
    FileUtils.cp_r(File.join(templates_dir, '.'), compile_dir)
  end
end
