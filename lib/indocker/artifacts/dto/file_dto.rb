class Indocker::Artifacts::DTO::FileDTO
  attr_reader :source_path, :target_path

  def initialize(source_path:, target_path:)
    @source_path = source_path
    @target_path = target_path
  end
end