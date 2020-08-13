class Indocker::SshResultLogger
  def initialize(logger)
    @logger = logger
  end

  def log(result, error_message)
    if result.exit_code == 0
      puts result.stdout_data
    else
      @logger.error(error_message)
      puts result.stdout_data

      result.stderr_data.to_s.split("\n").each do |line|
        @logger.error(line)
      end
    end
  end
end