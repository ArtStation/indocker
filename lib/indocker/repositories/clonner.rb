require 'net/ssh'

class Indocker::Repositories::Clonner
  def initialize(configuration, logger)
    @configuration = configuration
    @logger = logger
  end

  def clone(session, repository)
    raise ArgumenError.new("only git repositories should be clonned") if !repository.is_git?

    session.exec!("rm -rf #{repository.clone_path} && mkdir -p #{repository.clone_path}")
    session.exec!("git clone -b #{repository.branch} --depth 1 #{repository.remote_url} #{repository.clone_path}")
  end
end
