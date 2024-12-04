require 'digest'
require 'fileutils'

class Indocker::DeployContext
  attr_reader :configuration, :logger

  def initialize(logger:, configuration:)
    @logger = logger
    @configuration = configuration
    @restart_policy = Indocker::Containers::RestartPolicy.new(configuration, logger)
  end

  def deploy(container, force_restart)
    @logger.info("Deploying container: #{container.name.to_s.green}")
    @logger.debug("Deploy dir: #{Indocker.deploy_dir}")

    Indocker::Docker.pull(container.image.registry_url) if !container.image.registry.is_local?

    container.networks.each do |network|
      Indocker::Docker.create_network(
        Indocker::Networks::NetworkHelper.name(@configuration.name, network)
      )
    end

    container.volumes.each do |volume|
      if volume.is_a?(Indocker::Volumes::External)
        Indocker::Docker.create_volume(
          Indocker::Volumes::VolumeHelper.name(@configuration.name, volume)
        )
      end
    end

    container.get_start_option(:scale).times do |number|
      arg_list = Indocker::DockerRunArgs
        .get(container, @configuration, number)
        .join(' ')

      hostname = Indocker::ContainerHelper.hostname(@configuration.name, container, number)

      # timestamp generation
      run_cmd = Indocker::Docker.run_command(container.image.registry_url, arg_list, container.start_command, container.get_start_option(:service_args))

      env_files = container.get_start_option(:env_files, default: [])
        .map { |env_file|
          env_file = @configuration.env_files.fetch(env_file)
          File.read(Indocker::EnvFileHelper.path(env_file))
        }
        .join

      image_id = Indocker::Docker.image_id(container.image.registry_url)
      timestamp = Digest::MD5.hexdigest(run_cmd + image_id.to_s + env_files)

      binary_path = File.join(File.expand_path(Indocker.deploy_dir), 'bin')
      FileUtils.mkdir_p(binary_path)

      binary_path = File.join(binary_path, hostname)

      File.open(binary_path, 'w') { |f|
        f.write("#!/bin/bash\n\n")
        f.write(run_cmd)
      }

      FileUtils.chmod('+x', binary_path)

      container_id = Indocker::Docker.container_id_by_name(hostname)

      if !container_id || @restart_policy.restart?(container, timestamp) || force_restart
        if container.before_start_proc
          container.before_start_proc.call(container, number)
        end

        stop_timeout = container.get_start_option(:stop_timeout)

        if container_id
          Indocker::Docker.stop(hostname, time: stop_timeout, skip_errors: true)
        else
          Indocker::Docker.rm(hostname, skip_errors: true)
        end

        Indocker::Docker.run(container.image.registry_url, arg_list, container.start_command, container.get_start_option(:service_args))

        if container.after_start_proc
          container.after_start_proc.call(container, number)
        end

        @restart_policy.update(container, timestamp)
      else
        @logger.info("Skipping restart for container #{container.name.to_s.green} as no changes were found")

        if !container_id
          @restart_policy.update(container, timestamp)
        end
      end

      if container.after_deploy_proc
        container.after_deploy_proc.call(container, number)
      end
    end

    nil
  end
end
