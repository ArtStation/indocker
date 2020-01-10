class Indocker::ContainerHelper
  class << self
    def hostname(configuration_name, container, number = nil)
      scale = container.get_start_option(:scale)

      if scale == 1 || number.nil?
        "#{configuration_name}_#{container.name}"
      else
        "#{configuration_name}_#{container.name}_#{number}"
      end
    end
  end
end