class Indocker::Repositories::Local < Indocker::Repositories::Abstract
  attr_reader :root_path

  def setup(root_path)
    @root_path = File.expand_path(root_path)
    self
  end

  def project_name
    root_path.split('/').last
  end

  def root_path
    @root_path || (raise ArgumentError.new("root path was not set. Set it using setup method"))
  end

  def clone_path
    "/tmp/#{Indocker.configuration.name}/repositories/local/#{project_name}"
  end
end