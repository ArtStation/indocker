module Indocker::Concerns::Inspectable
  def inspect
    data = {}
    data[:type] = self.class.to_s.split('::').last.downcase

    instance_variables.each do |variable|
      data[variable.to_s.gsub('@', '').to_sym] = instance_variable_get(variable)
    end

    data.inspect
  end
end