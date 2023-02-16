class Indocker::Artifacts::Git < Indocker::Artifacts::Base
  attr_reader :name, :remote_name, :remote_url, :branch, :files, :ssh_key

  def initialize(name:, remote_name:, remote_url:, branch:, files: [], source_path: nil, target_path: nil, ssh_key: nil)
    @name        = name
    @remote_name = remote_name
    @remote_url  = remote_url
    @branch      = branch
    @ssh_key     = ssh_key

    @files = build_all_files(
      files:       files,
      source_path: source_path,
      target_path: target_path,
    )
  end

  def repository
    @repository ||= Indocker::Repositories::Git.new(@name).setup(
      remote_name: remote_name,
      remote_url:  remote_url,
      branch:      branch,
      ssh_key:     ssh_key,
      clone_path:  "/tmp/#{Indocker.configuration.name}/artifacts/git/#{project_name(remote_url)}/#{branch}"
    )
  end

  def project_name(url)
    url.split('/').last.gsub('.git', '')
  end

  def is_git?
    true
  end

  def build_source_path(path)
    File.join(self.repository.clone_path, path)
  end
end
