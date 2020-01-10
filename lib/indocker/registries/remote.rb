class Indocker::Registries::Remote < Indocker::Registries::Abstract
  attr_reader :server_name

  def setup(server_name)
    @server_name = server_name
    self
  end

  def url
    @server_name
  end
end