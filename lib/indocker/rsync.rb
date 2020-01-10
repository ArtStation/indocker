require_relative 'shell'

class Indocker::Rsync
  def self.local_sync(from, to, create_path: nil, raise_on_error: false, exclude: nil)
    @session ||= Indocker::SshSession.new(
      host: 'localhost',
      user: nil,
      port: nil,
      logger: Indocker.logger
    )

    sync(@session, from, to, create_path: create_path, raise_on_error: raise_on_error, exclude: exclude)
  end

  def self.sync(session, from, to, create_path: nil, raise_on_error: false, exclude: nil)
    if create_path
      session.exec!("mkdir -p #{create_path}")
    end

    if session.local?
      return if File.expand_path(to) == File.expand_path(from)

      Indocker::Shell.command("rm -rf #{to}", Indocker.logger, raise_on_error: raise_on_error)

      if Indocker::Shell.command_exist?("rsync")
        sync_local_rsync(from, to, raise_on_error: raise_on_error, exclude: exclude)
      else
        Indocker.logger.debug("WARNING: exclude option skipped due to fallback to CP command")
        sync_local_cp(from, to, raise_on_error: raise_on_error)
      end
    else
      command = "rsync --delete-after -a -e 'ssh -p #{session.port}' #{from} #{session.user}@#{session.host}:#{to}"
      Indocker.logger.debug("sync #{from} #{session.user}@#{session.host}:#{to}")
      Indocker::Shell.command(command, Indocker.logger, raise_on_error: raise_on_error)
    end
  end

  private
    def self.sync_local_cp(from, to, raise_on_error:)
      Indocker::Shell.command("cp -r #{from} #{to}", Indocker.logger, raise_on_error: raise_on_error)
    end

    def self.sync_local_rsync(from, to, raise_on_error:, exclude: nil)
      options = []
      options << " --exclude=#{exclude}" if exclude
      # Add a trailing slash to directory to have behavior similar to CP command
      if File.directory?(from) && !from.end_with?("/")
        from = "#{from}/"
      end
      Indocker::Shell.command("rsync -a #{options.join(' ')} #{from} #{to}", Indocker.logger, raise_on_error: raise_on_error)
    end
end