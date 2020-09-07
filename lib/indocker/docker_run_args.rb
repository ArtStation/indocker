class Indocker::DockerRunArgs
  DEFAULT_LOG_MAX_SIZE = "400m"
  DEFAULT_LOG_MAX_FILE = "2"

  class << self
    def get(container, configuration, number)
      args = []
      restart = container.get_start_option(:restart)

      if restart
        args.push("--restart #{restart}")
      end

      env_files = container.get_start_option(:env_files)

      if env_files
        env_files = env_files.is_a?(Array) ? env_files : [env_files]

        env_files.each do |val|
          env_file = configuration.env_files.fetch(val) do
            Indocker.logger.error("env file :#{val} for container :#{container.name} is not specified in configuration :#{configuration.name}")
            exit 1
          end

          path = Indocker::EnvFileHelper.path(env_file)

          if !File.exists?(path)
            raise ArgumentError.new("env file not found: #{path}")
          end

          args.push("--env-file #{path}")
        end
      end

      expose = container.get_start_option(:expose)

      if expose
        expose = expose.is_a?(Array) ? expose : [expose]

        expose.each do |val|
          args.push("--expose #{val}")
        end
      end

      ports = container.get_start_option(:ports)

      if ports
        ports = ports.is_a?(Array) ? ports : [ports]

        ports.each do |val|
          args.push("--publish #{val}")
        end
      end

      environment = container.get_start_option(:environment)

      if environment
        environment.each do |key, val|
          args.push("--env #{key}=#{val}")
        end
      end

      sysctl = container.get_start_option(:sysctl)
      
      if sysctl
        Array(sysctl).each do |val|
          args.push("--sysctl #{val}")
        end
      end

      if container.is_daemonized?
        args.push("--detach")
      end

      hostname = Indocker::ContainerHelper.hostname(configuration.name, container, number)
      args.push("--hostname #{hostname}")
      args.push("--name #{hostname}")

      read_only = container.get_start_option(:read_only) || false

      if read_only
        args.push("--read-only")
      end

      labels = container.get_start_option(:labels) || []

      labels += container.tags
      labels.uniq!

      labels.each do |label|
        args.push("--label #{label}")
      end

      stop_timeout = container.get_start_option(:stop_timeout)

      if stop_timeout
        args.push("--stop-timeout #{stop_timeout}")
      end

      add_hosts = container.get_start_option(:add_hosts) || []

      add_hosts.each do |host|
        args.push("--add-host #{host}")
      end

      mounts = container.get_start_option(:mounts) || []

      mounts.each do |mount|
        args.push("--mount #{mount}")
      end

      nets = container.get_start_option(:nets) || []

      nets.each do |net|
        args.push("--net #{net}")
      end

      user = container.get_start_option(:user)

      if user
        args.push("--user #{user}")
      end

      max_size = container.get_start_option(:max_size) || DEFAULT_LOG_MAX_SIZE

      if max_size
        args.push("--log-opt max-size=#{max_size}")
      end

      max_file = container.get_start_option(:max_file) || DEFAULT_LOG_MAX_FILE

      if max_file
        args.push("--log-opt max-file=#{max_file}")
      end

      health = container.get_start_option(:health) || {}

      if !health.is_a?(Hash)
        raise ArgumentError.new("health should be a Hash for container :#{container.name}")
      end

      if health.has_key?(:cmd)
        args.push("--health-cmd \"#{health[:cmd]}\"")
      end

      if health.has_key?(:interval)
        args.push("--health-interval #{health[:interval]}")
      end

      if health.has_key?(:retries)
        args.push("--health-retries #{health[:retries]}")
      end

      if health.has_key?(:timeout)
        args.push("--health-timeout #{health[:timeout]}")
      end

      container.volumes.each do |volume|
        if volume.is_a?(Indocker::Volumes::Local)
          args.push("-v #{volume.local_path}:#{volume.path}")
        elsif volume.is_a?(Indocker::Volumes::External)
          name = Indocker::Volumes::VolumeHelper.name(configuration.name, volume)
          args.push("-v #{name}:#{volume.path}")
        elsif volume.is_a?(Indocker::Volumes::Repository)
          repository = configuration.repositories.fetch(volume.repository_name) do
            raise ArgumentError.new("specified repository :#{volume.repository_name} for volume :#{volume.name} was not found")
          end

          args.push("-v #{File.join(repository.clone_path)}:#{volume.path}:cached")
        else
          raise NotImplementedError.new("unsupported volume type: #{volume.inspect}")
        end
      end

      container.networks.each do |network|
        name = Indocker::Networks::NetworkHelper.name(configuration.name, network)
        args.push("--network #{name}")
      end

      args
    end
  end
end