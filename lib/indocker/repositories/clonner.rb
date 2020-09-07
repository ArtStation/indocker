require 'net/ssh'

class Indocker::Repositories::Clonner
  def initialize(configuration, logger)
    @configuration = configuration
    @logger = logger
  end

  def clone(session, repository)
    raise ArgumenError.new("only git repositories should be clonned") if !repository.is_git?

    repository_remote_url = session.exec!(
      build_git_remote_url_command(
        path: repository.clone_path
      )
    ).stdout_data.chomp

    @logger.debug("server remote_url:  #{repository_remote_url.inspect}, indocker remote_url: #{repository.remote_url.inspect}")

    git_command = if repository_remote_url == repository.remote_url
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

    def build_git_remote_url_command(path:)
      "mkdir -p #{path} && cd #{path} && git config --get remote.origin.url"
    end

    def build_clone_command(target_path:, branch_name:, remote_url:)
      "rm -rf #{target_path} && mkdir -p #{target_path} && git clone -b #{branch_name} --depth 1 #{remote_url} #{target_path}"
    end

    def build_force_pull_command(target_path:, branch_name:)
      "cd #{target_path} && git add . && git reset HEAD --hard && git checkout #{branch_name} && git pull --force"
    end
end