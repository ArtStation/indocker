class Indocker::Artifacts::Git < Indocker::Artifacts::Base
  attr_reader :name, :remote_name, :remote_url, :branch, :files

  def initialize(name:, remote_name:, remote_url:, branch:, files: [], source_path: nil, target_path: nil)
    @name        = name
    @remote_name = remote_name
    @remote_url  = remote_url
    @branch      = branch

    File.join(self.repository.clone_path, repository_relative_path)

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
      clone_path:  "/tmp/#{Indocker.configuration.name}/artifacts/git/#{project_name(remote_url)}/#{branch}"
    )
  end

  def project_name(url)
    url.split('/').last.gsub('.git', '')
  end

  def is_git?
    true
  end

  private

    def build_all_files(files: [], source_path:, target_path:)
      all_files = []

      files.map do |file_dto|
        Indocker::Artifacts::DTO::FileDTO.new(
          source_path: File.join(self.repository.clone_path, file_dto.source_path),
          target_path: file_dto.target_path
        )
      end

      if source_path && target_path
        all_files.push(
          Indocker::Artifacts::DTO::FileDTO.new(
            source_path: File.join(self.repository.clone_path, file_dto.source_path),
            target_path: target_path,
          )
        )
      end

      all_files
    end
end