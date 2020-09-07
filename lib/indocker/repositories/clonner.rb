require 'net/ssh'

class Indocker::Repositories::Clonner
  def initialize(configuration, logger)
    @configuration = configuration
    @logger = logger
  end

  def clone(session, repository)
    raise ArgumenError.new("only git repositories should be clonned") if !repository.is_git?

    already_clonned = repository_already_clonned?(
      session:     session,
      target_path: repository.clone_path,
      remote_url:  repository.remote_url,
    )

    git_command = if already_clonned
      build_force_pull_command(
        target_path: repository.clone_path,
        branch_name: repository.branch,
      )
    else
      build_clone_command(
        target_path: repository.clone_path,
        branch_name: repository.branch,
        remote_url:  repository.remote_url,
      )
    end

    session.exec!("ssh-agent bash -c 'ssh-add ~/.ssh/#{repository.ssh_key}; #{git_command}'")
  end

  private

    def repository_already_clonned?(session:, target_path:, remote_url:)
      target_remote_url = session.exec!(
        build_git_remote_url_command(
          path: repository.clone_path
        )
      ).stdout_data.chomp

      @logger.debug("target remote_url:  #{target_remote_url.inspect}, checked remote_url: #{remote_url.inspect}")

      target_remote_url == remote_url
    end

    def build_git_remote_url_command(path:)
      [
        "mkdir -p #{path}",
        "cd #{path}",
        "git config --get remote.origin.url",
      ].join(" && ")
    end

    def build_clone_command(target_path:, branch_name:, remote_url:)
      [
        "rm -rf #{target_path}",
        "mkdir -p #{target_path}",
        "git clone -b #{branch_name} --depth 1 #{remote_url} #{target_path}",
      ].join(" && ")
    end

    def build_force_pull_command(target_path:, branch_name:)
      [
        "cd #{target_path}",
        "git add .",
        "git reset HEAD --hard",
        "git checkout #{branch_name}",
        "git pull --force",
      ].join(" && ")
    end
end