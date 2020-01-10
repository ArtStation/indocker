class Indocker::NetworkHelper
  class << self
    def name(configuration_name, network)
      "#{configuration_name}_#{network.name}"
    end
  end
end