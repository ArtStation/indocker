class Indocker::Network
  attr_reader :name, :containers

  def initialize(name)
    @name = name
    @containers = []
  end

  def add_container(container)
    @containers.push(container) if !@containers.include?(container)
  end
end