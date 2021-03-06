require 'erb'

class Indocker::Images::TemplateCompiler
  def compile(path, context)
    Indocker.logger.debug("compiling template file #{path}".grey)
    template = File.read(path)
    content = ERB.new(template).result(context.helper.get_binding)
    File.write(path, content)
  rescue Errno::EACCES => e
    # do nothing for read only files
  rescue => e
    Indocker.logger.error("compilation failed for template file #{path}. #{e.inspect}")
    raise e
  end
end
