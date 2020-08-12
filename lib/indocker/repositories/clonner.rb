require 'net/ssh'

class Indocker::Repositories::Clonner
  def initialize(configuration, logger)
    @configuration = configuration
    @logger = logger
  end

  def clone(session, repository)
    raise ArgumenError.new("only git repositories should be clonned") if !repository.is_git?

    repository_remote_url = session.exec!("mkdir -p #{repository.clone_path} && cd #{repository.clone_path} && git config --get remote.origin.url").stdout_data.chomp

    @logger.debug("server remote_url => #{repository_remote_url.inspect}, indocker remote_url => #{repository.remote_url.inspect}")

    git_command = if repository_remote_url == repository.remote_url
      "cd #{repository.clone_path} && git add . && git reset HEAD --hard && git checkout #{repository.branch} && git pull --force"
    else
      "rm -rf #{repository.clone_path} && mkdir -p #{repository.clone_path} && git clone -b #{repository.branch} --depth 1 #{repository.remote_url} #{repository.clone_path}"
    end

    session.exec!("ssh-agent bash -c 'ssh-add ~/.ssh/#{repository.ssh_key}; #{git_command}'")
  end
end