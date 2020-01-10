require 'fileutils'

class Indocker::Containers::RestartPolicy
  TIMESTAMPS_DIR = 'timestamps'

  def initialize(configuration, logger)
    @configuration = configuration
    @logger = logger
  end

  def restart?(container, timestamp)
    file = timestamp_file(container)
    return true if !File.exists?(file)

    last_timestamp = File.read(file).strip
    timestamp != last_timestamp
  end

  def update(container, timestamp)
    FileUtils.mkdir_p(timestamp_folder)

    File.open(timestamp_file(container), 'w') do |f|
      f.write(timestamp)
    end
  end

  private

  def timestamp_folder
    timestamp = File.join(File.expand_path(Indocker.deploy_dir), TIMESTAMPS_DIR)
  end

  def timestamp_file(container)
    File.join(timestamp_folder, container.name.to_s)
  end
end