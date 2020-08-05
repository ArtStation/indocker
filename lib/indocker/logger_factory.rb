class Indocker::LoggerFactory
  class << self
    def create(stdout, level = nil)
      logger = Logger.new(stdout)

      logger.level = level || Logger::INFO

      logger.formatter = proc do |severity, datetime, progname, msg|
        level = Logger::SEV_LABEL.index(severity)

        severity = case level
        when Logger::INFO
          severity.green
        when Logger::WARN
          severity.purple
        when Logger::DEBUG
          severity.yellow
        when Logger::ERROR
          severity.red
        when Logger::FATAL
          severity.red
        else
          severity
        end

        severity = severity.downcase
        if logger.debug?
          "#{datetime.strftime("%Y/%m/%d %H:%M:%S")} #{severity}: #{msg}\n"
        else
          "  #{severity}: #{msg}\n"
        end
      end

      logger
    end
  end
end