class Indocker::Artifacts::Git
  attr_reader :name, :remote_name, :remote_url, :branch, :files

  def initialize(name:, remote_name:, remote_url:, branch:, files:)
    @name        = name
    @remote_name = remote_name
    @remote_url  = remote_url
    @branch      = branch
    @files       = files
  end

  def repository
    @repository ||= Indocker::Repositories::Git.new(@name).setup(
      remote_name: remote_name,
      remote_url:  remote_url,
      branch:      branch,
      clone_path:  "/tmp/#{Indocker.configuration.name}/artifacts/git/#{project_name(remote_url)}/#{branch}"
    )
  end

  def project_name(url)
    url.split('/').last.gsub('.git', '')
  end
end