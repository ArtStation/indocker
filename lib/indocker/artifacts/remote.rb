class Indocker::Artifacts::Remote < Indocker::Artifacts::Base
  attr_reader :name, :files

  def initialize(name:, files: [], source_path: nil, target_path: nil)
    @name = name

    @files       = build_all_files(
      files:       files,
      source_path: source_path,
      target_path: target_path,
    )
  end

  def build_source_path(path)
    path
  end
end