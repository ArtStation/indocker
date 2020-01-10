class Indocker::Repositories::Abstract
  include Indocker::Concerns::Inspectable

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def setup(*args)
    self
  end

  def is_local?
    self.is_a?(Indocker::Repositories::Local)
  end

  def is_git?
    self.is_a?(Indocker::Repositories::Git)
  end

  def is_no_sync?
    self.is_a?(Indocker::Repositories::NoSync)
  end
end