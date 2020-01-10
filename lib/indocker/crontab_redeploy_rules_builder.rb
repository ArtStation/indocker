class Indocker::CrontabRedeployRulesBuilder
  CRONTAB = <<-CRONTAB
SHELL=/bin/bash
PATH=/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

%{rules}

  CRONTAB

  LOG_FILE      = "/var/log/indocker-redeploy-%{env}.log"
  COMMAND       = "export TERM=xterm;#{Indocker.deploy_dir}/indocker/bin/deploy -C %{env} -f -B -y -c %{container_name}"
  REDEPLOY_RULE = %Q{%{schedule} echo `date` "- %{command}..." >> %{log_file}; %{command} 1>/dev/null 2>>%{log_file}; echo `date` "- done, exitcode = $?" >> %{log_file}}

  def initialize(configuration:, logger:)
    @configuration  = configuration
    @logger         = logger
  end

  def call(containers)
    CRONTAB % {
      rules: containers.map{ |c| redeploy_rule(c) }.join("\n"),
    }
  end

  private
  def self.env
    Indocker.configuration_name
  end

  def env
    self.class.env
  end

  def log_file
    LOG_FILE % {
      env: env,
    }
  end

  def command(container)
    COMMAND % {
      env:            env,
      container_name: container.name,
    }
  end

  def redeploy_rule(container)
    REDEPLOY_RULE % {
      schedule:   container.redeploy_schedule,
      command:    command(container),
      log_file:   log_file,
    }
  end
end