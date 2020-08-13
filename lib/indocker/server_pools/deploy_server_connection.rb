class Indocker::ServerPools::DeployServerConnection < Indocker::ServerPools::ServerConnection
  def run_container_remotely(configuration_name:, container_name:, force_restart:)
    command_output  = @logger.debug? ? "" : " > /dev/null"
    debug_options   = @logger.debug? ? "-d" : ""
    force_restart_options = force_restart ? "-f" : ""

    result = exec!(
      "cd #{Indocker::IndockerHelper.indocker_dir} && ./bin/remote/run -C #{configuration_name} -c #{container_name} #{debug_options} #{command_output} #{force_restart_options}"
    )

    Indocker::SshResultLogger
      .new(@logger)
      .log(result, "#{container_name.to_s.green} deployment for server #{server.name} failed")
    
    result
  end
end