class Indocker::EnvFiles::Remote
  attr_reader :name, :path

  def initialize(name, path)
    @name = name
    @path = path
  end
end