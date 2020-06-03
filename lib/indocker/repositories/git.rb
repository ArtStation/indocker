class Indocker::Repositories::Git < Indocker::Repositories::Abstract
  attr_reader :remote_url, :remote_name, :email, :password, :branch, :ssh_key

  DEFAULT_SSH_KEY = "id_rsa"

  def setup(remote_name:, remote_url:, email: nil, password: nil, branch:, clone_path: nil, ssh_key: DEFAULT_SSH_KEY)
    @remote_name = remote_name
    @remote_url = remote_url
    @email = email
    @password = password
    @branch = branch
    @clone_path = clone_path
    @ssh_key = ssh_key
    self
  end

  def project_name
    @remote_url.split('/').last.gsub('.git', '')
  end

  def clone_path
    @clone_path || "/tmp/#{Indocker.configuration.name}/repositories/git/#{project_name}/#{branch}"
  end
end