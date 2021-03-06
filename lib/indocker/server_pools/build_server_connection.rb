require 'fileutils'

class Indocker::ServerPools::BuildServerConnection < Indocker::ServerPools::ServerConnection
  def compile_image_remotely(configuration_name:, image_name:)
    result = exec!(
      "cd #{Indocker::IndockerHelper.indocker_dir} && ./bin/remote/compile -C #{configuration_name} -i #{image_name} -s #{@logger.debug? ? '-d' : ''}"
    )

    Indocker::SshResultLogger
      .new(@logger)
      .log(result, "#{image_name.to_s.green} image compilation failed")
    
    result
  end
end