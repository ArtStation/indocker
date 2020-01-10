require_relative 'shell'

class Indocker::SshSession
  LOCALHOST = 'localhost'.freeze

  class ExecResult
    attr_reader :stdout_data, :stderr_data, :exit_code, :exit_signal

    def initialize(stdout_data, stderr_data, exit_code, exit_signal)
      @stdout_data = stdout_data
      @stderr_data = stderr_data
      @exit_code = exit_code
      @exit_signal = exit_signal
    end


    def success?
      @exit_code == 0
    end
  end

  attr_reader :host, :user, :port, :logger

  def initialize(host:, user:, port:, logger:)
    @host = host
    @user = user
    @port = port
    @logger = logger

    if host != LOCALHOST
      require 'net/ssh'
      @ssh = Net::SSH.start(@host, @user, {port: @port})
    end
  end

  def local?
    !@ssh
  end

  def exec!(command)
    if !@ssh
      res = Indocker::Shell.command_with_result(command, @logger, skip_logging: false)
      ExecResult.new(res.stdout, '', res.exit_status, nil)
    else
      if Indocker.export_command
        command = "#{Indocker.export_command} && #{command}"
      end

      stdout_data = ''
      stderr_data = ''
      exit_code = nil
      exit_signal = nil

      @logger.debug("(#{@user}:#{@host}:#{@port}): executing command: #{command}")

      @ssh.open_channel do |channel|
        channel.exec(command) do |ch, success|
          if !success
            @logger.error("(#{@user}@#{@host}:#{@port}): couldn't execute command: #{command}")
            abort('failed')
          end

          channel.on_data do |ch,data|
            stdout_data += data
          end

          channel.on_extended_data do |ch,type,data|
            stderr_data += data
          end

          channel.on_request('exit-status') do |ch,data|
            exit_code = data.read_long
          end

          channel.on_request('exit-signal') do |ch, data|
            exit_signal = data.read_long
          end
        end
      end

      @ssh.loop

      ExecResult.new(stdout_data, stderr_data, exit_code, exit_signal)
    end
  end

  def close
    if @ssh
      @ssh.close
    end
  end
end