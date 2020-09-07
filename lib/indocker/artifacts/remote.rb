class Indocker::Artifacts::Remote
  attr_reader :name, :files

  def initialize(name:, files:)
    @name  = name
    @files = files
  end

  def build_source_path(source_path)
    source_path
  end

  def build_source_path(target_path)
    target_path
  end
end