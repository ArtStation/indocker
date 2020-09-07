class Indocker::Artifacts::Base

  def build_source_path(*args)
    raise StandardError.new('not implemented')
  end

  def build_source_path(*args)
    raise StandardError.new('not implemented')
  end

  def is_git?
    false
  end

  private

    def build_all_files(files: [], source_path: nil, target_path: nil)
      all_files = files

      if source_path && target_path
        all_files.push(
          Indocker::Artifacts::DTO::FileDTO.new(
            source_path: source_path,
            target_path: target_path,
          )
        )
      end

      all_files
    end
end