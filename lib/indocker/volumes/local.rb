class Indocker::Volumes::Local
  attr_reader :name, :local_path, :path

  def initialize(name, local_path, path)
    @name = name
    @local_path = local_path
    @path = path
  end
end