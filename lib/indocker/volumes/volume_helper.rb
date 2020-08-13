class Indocker::Volumes::VolumeHelper
  class << self
    def name(configuration_name, volume)
      "#{configuration_name}_#{volume.name}"
    end
  end
end