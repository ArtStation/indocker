class Indocker::Registries::Abstract
  include Indocker::Concerns::Inspectable

  attr_reader :repository_name

  def initialize(repository_name)
    @repository_name = repository_name
  end

  def setup(*args)
    self
  end

  def is_local?
    self.is_a?(Indocker::Registries::Local)
  end
end