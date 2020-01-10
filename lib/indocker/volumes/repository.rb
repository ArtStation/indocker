class Indocker::Volumes::Repository
  attr_reader :name, :repository_name, :path

  def initialize(name, repository_alias_name, path)
    @name = name
    @repository_name = repository_alias_name
    @path = path
  end
end