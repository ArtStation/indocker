class Indocker::Containers::Container
  attr_reader :name, :parent_containers, :dependent_containers, :soft_dependent_containers,
              :volumes, :networks, :servers, :start_command,
              :before_start_proc, :after_start_proc, :after_deploy_proc,
              :build_args, :start_options, :redeploy_schedule

  def initialize(name)
    @name = name
    @daemonize = true
    @parent_containers = []
    @dependent_containers = []
    @soft_dependent_containers = []
    @volumes = []
    @networks = []
    @servers = []
    @start_options = {}
    @build_args = {}
    @redeploy_schedule = nil
  end

  def set_build_args(opts)
    @build_args = opts
  end

  def set_before_start_proc(proc)
    @before_start_proc = proc
  end

  def set_after_start_proc(proc)
    @after_start_proc = proc
  end

  def set_after_deploy_proc(proc)
    @after_deploy_proc = proc
  end

  def set_start_command(name)
    @start_command = name
  end

  def set_tags(tag_list)
    @tags = tag_list
  end

  def set_scale(count)
    @start_options[:scale] = count
  end

  def set_attached
    @daemonize = false
  end

  def tags
    @tags || (raise ArgumentError.new("tags not defined for container :#{@name}"))
  end

  def set_image(image)
    @image = image
  end

  def image
    @image || (raise ArgumentError.new("image not defined for container :#{@name}"))
  end

  def servers
    @servers || (raise ArgumentError.new("servers not defined for container :#{@name}"))
  end

  def daemonize(flag)
    @daemonize = flag
    @attach = false
  end

  def is_daemonized?
    @daemonize
  end

  def set_servers(servers)
    @servers = servers
  end

  def add_parent_container(container)
    @parent_containers.push(container) if !@parent_containers.include?(container)
  end

  def add_dependent_container(container)
    container.add_parent_container(self)
    @dependent_containers.push(container) if !@dependent_containers.include?(container)
  end

  def add_soft_dependent_container(container)
    @soft_dependent_containers.push(container) if !@soft_dependent_containers.include?(container)
  end

  def set_start_options(opts)
    @start_options = opts
  end

  def get_start_option(name, default: nil)
    @start_options.fetch(name) { default }
  end

  def set_volumes(volumes)
    @volumes = volumes
  end

  def set_networks(networks)
    @networks = networks

    networks.each do |network|
      network.add_container(self)
    end
  end

  def set_redeploy_schedule(schedule)
    @redeploy_schedule = schedule
  end
end