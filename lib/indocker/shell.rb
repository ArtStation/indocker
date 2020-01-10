class Indocker::Shell
  class ShellResult
    attr_reader :exit_status, :stdout

    def initialize(stdout, exit_status)
      @stdout = stdout
      @exit_status = exit_status
    end
  end

  class ShellCommandError < StandardError
  end

  class << self
    def command(command, logger, skip_errors: false, raise_on_error: false, &block)
      if logger.debug?
        logger.debug("Executing command: #{command.cyan}")
      end

      system(command, out: (logger.debug? ? $stdout : File::NULL), err: :out)

      if !$?.success? && !skip_errors
        logger.error("Command: #{command.cyan} failed")

        if raise_on_error
          raise ShellCommandError.new("Command: #{command.cyan} failed")
        else
          exit 1
        end
      end

      if block_given?
        yield
      end
    end

    def command_with_result(command, logger, skip_logging: false)
      if !skip_logging && logger.debug?
        logger.debug("Executing command: #{command.cyan}")
      end

      result = nil

      IO.popen(command, err: [:child, :out]) do |io|
        result = io.read.chomp.strip

        if !skip_logging
          logger.debug(result)
        end
      end

      ShellResult.new(result, $?.exitstatus)
    end

    def command_exist?(command_name)
      `which #{command_name}`
      $?.success?
    end
  end
end
