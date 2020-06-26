require "indocker/version"
require 'logger'
$LOAD_PATH << File.join(__dir__, 'indocker')

require_relative 'indocker/colored_string'

module Indocker
  module Repositories
    autoload :Abstract, 'repositories/abstract'
    autoload :Git, 'repositories/git'
    autoload :Local, 'repositories/local'
    autoload :NoSync, 'repositories/no_sync'
    autoload :Clonner, 'repositories/clonner'
  end

  module Configurations
    autoload :Configuration, 'configurations/configuration'
    autoload :ConfigurationBuilder, 'configurations/configuration_builder'

    module Formatters
      autoload :Stdout, 'configurations/formatters/stdout'
    end
  end

  module Registries
    autoload :Abstract, 'registries/abstract'
    autoload :Local, 'registries/local'
    autoload :Remote, 'registries/remote'
  end

  module Concerns
    autoload :Inspectable, 'concerns/inspectable'
  end

  module Images
    autoload :Image, 'images/image'
    autoload :ImageBuilder, 'images/image_builder'
    autoload :ImageCompiler, 'images/image_compiler'
    autoload :TemplateCompiler, 'images/template_compiler'
    autoload :TemplatesCompiler, 'images/templates_compiler'
  end

  module Containers
    autoload :Container, 'containers/container'
    autoload :ContainerBuilder, 'containers/container_builder'
    autoload :RestartPolicy, 'containers/restart_policy'
  end

  module Volumes
    autoload :Local, 'volumes/local'
    autoload :External, 'volumes/external'
    autoload :Repository, 'volumes/repository'
  end

  module EnvFiles
    autoload :Local, 'env_files/local'
    autoload :Remote, 'env_files/remote'
  end

  module Artifacts
    autoload :Git, 'artifacts/git'
  end

  autoload :HashMerger, 'hash_merger'
  autoload :BuildServer, 'build_server'
  autoload :Server, 'server'
  autoload :ConfigurationDeployer, 'configuration_deployer'
  autoload :SshSession, 'ssh_session'
  autoload :BuildContextPool, 'build_context_pool'
  autoload :BuildContext, 'build_context'
  autoload :BuildContextHelper, 'build_context_helper'
  autoload :Shell, 'shell'
  autoload :Docker, 'docker'
  autoload :ContextArgs, 'context_args'
  autoload :Network, 'network'
  autoload :ContainerDeployer, 'container_deployer'
  autoload :ServerPool, 'server_pool'
  autoload :DeployContext, 'deploy_context'
  autoload :ContainerHelper, 'container_helper'
  autoload :DockerRunArgs, 'docker_run_args'
  autoload :VolumeHelper, 'volume_helper'
  autoload :NetworkHelper, 'network_helper'
  autoload :Rsync, 'rsync'
  autoload :EnvFileHelper, 'env_file_helper'
  autoload :IndockerHelper, 'indocker_helper'
  autoload :ImagesCompiler, 'images_compiler'
  autoload :ContainerRunner, 'container_runner'
  autoload :SshResultLogger, 'ssh_result_logger'
  autoload :DeploymentProgress, 'deployment_progress'
  autoload :DeploymentChecker, 'deployment_checker'
  autoload :CrontabRedeployRulesBuilder, 'crontab_redeploy_rules_builder'

  class << self
    def set_export_command(command)
      @export_command = command
    end

    def export_command
      @export_command
    end

    def set_deploy_dir(val)
      @deploy_dir = val
    end

    def set_root_dir(val)
      @root_dir = val
    end

    def set_redeploy_crontab_path(val)
      @redeploy_crontab_path = val
    end

    def redeploy_crontab_path
      @redeploy_crontab_path
    end

    def deploy_dir
      if @deploy_dir
        @deploy_dir
      else
        raise ArgumentError.new("deploy dir was not specified")
      end
    end

    def root_dir
      if @root_dir
        File.expand_path(@root_dir)
      else
        raise ArgumentError.new("root dir was not specified")
      end
    end

    def add_artifact(artifact)
      artifacts.push(artifact)
    end

    def add_repository(repository)
      if !repository.is_a?(Indocker::Repositories::Abstract)
        raise ArgumentError.new("should be an instance of Indocker::Repositories::Abstract, got: #{repository.inspect}")
      end

      repositories.push(repository)
    end

    def add_registry(registry)
      if !registry.is_a?(Indocker::Registries::Abstract)
        raise ArgumentError.new("should be an instance of Indocker::Registries::Abstract, got: #{registry.inspect}")
      end

      registries.push(registry)
    end

    def add_server(server)
      if !server.is_a?(Indocker::Server)
        raise ArgumentError.new("should be an instance of Indocker::Server, got: #{server.inspect}")
      end

      existing = servers.detect {|s| s == server}

      if existing
        raise ArgumentError.new("server with name #{server.name} was already defined")
      end

      servers.push(server)
    end

    def define_network(name)
      if networks.detect {|n| n.name == name}
        raise ArgumentError.new("network :#{name} was already defined")
      end

      networks.push(Indocker::Network.new(name))
    end

    def container_files
      @container_files || (raise ArgumentError.new("container files were not found. Set bounded contexts dir"))
    end

    def image_files
      @image_files || (raise ArgumentError.new("image files were not found. Set bounded contexts dir"))
    end

    def set_bounded_contexts_dir(path)
      @container_files = {}

      Dir[File.join(path, '**/container.rb')].map do |path|
        name = path.gsub('/container.rb', '').split('/').last.to_sym
        @container_files[name] = path
      end

      @image_files = {}

      Dir[File.join(path, '**/image.rb')].map do |path|
        name = path.gsub('/image.rb', '').split('/').last.to_sym
        @image_files[name] = path
      end
    end

    def define_env_file(env_file)
      if env_files.detect {|ef| ef.name == env_file.name}
        Indocker.logger.error("env file :#{env_file.name} was already defined")
        exit 1
      end

      env_files.push(env_file)
    end

    def define_volume(volume)
      if volumes.detect { |v| v.name == volume.name}
        raise ArgumentError.new("volume :#{volume.name} was already defined")
      end

      volumes.push(volume)
    end

    def add_build_server(build_server)
      if !build_server.is_a?(Indocker::BuildServer)
        raise ArgumentError.new("should be an instance of Indocker::BuildServer, got: #{build_server.inspect}")
      end

      existing = build_servers.detect {|s| s == build_server}

      if existing
        raise ArgumentError.new("build server with name #{build_server.name} was already defined")
      end

      build_servers.push(build_server)
    end

    def repositories
      @repositories ||= []
    end

    def registries
      @registries ||= []
    end

    def networks
      @networks ||= []
    end

    def volumes
      @volumes ||= []
    end

    def servers
      @servers ||= []
    end

    def artifacts
      @artifacts ||= []
    end

    def build_servers
      @build_servers ||= []
    end

    def env_files
      @env_files ||= []
    end

    def configuration
      @configuration || (raise ArgumentError.new("no configuration provided"))
    end

    def images
      @images ||= []
    end

    def containers
      @containers ||= []
    end

    def build_configuration(name)
      builder = Indocker::Configurations::ConfigurationBuilder.new(
        name: name,
        repositories: repositories,
        registries: registries,
        servers: servers,
        build_servers: build_servers,
        volumes: volumes,
        networks: networks,
        env_files: env_files,
        containers: containers,
      )

      @configuration = builder.configuration
      builder
    end

    def define_image(name)
      path = caller[0].split(':').first

      if !(path =~ /\/image.rb$/)
        Indocker.logger.error("image :#{name} should be defined in image.rb file")
        exit 1
      end

      builder = Indocker::Images::ImageBuilder.new(
        name: name,
        configuration: configuration,
        dir: path.split('image.rb').first
      )

      images.push(builder.image)

      builder
    end

    def define_container(name)
      builder = Indocker::Containers::ContainerBuilder.new(
        name: name,
        configuration: configuration,
      )

      containers.push(builder.container)
      builder
    end

    def deploy(containers: [], skip_tags: [], tags: [], skip_dependent: false, skip_containers: [], servers: [], skip_build: false, force_restart: false, skip_force_restart: [], auto_confirm: false, require_confirmation: false)
      Indocker::ConfigurationDeployer
        .new(Indocker.logger)
        .run(
          configuration: configuration,
          deploy_containers: containers,
          deploy_tags: tags,
          skip_dependent: skip_dependent,
          skip_containers: skip_containers,
          servers: servers,
          skip_build: skip_build,
          force_restart: force_restart,
          skip_tags: skip_tags,
          skip_force_restart: skip_force_restart,
          auto_confirm: auto_confirm,
          require_confirmation: require_confirmation,
        )
    end

    def check(servers: [])
      Indocker::DeploymentChecker
        .new(Indocker.logger)
        .run(
          configuration: configuration,
          servers: servers,
        )
    end

    def launched?(contaner_name, servers: [])
      silent_logger = Logger.new(File.open(File::NULL, "w"))
      Indocker::DeploymentChecker
        .new(silent_logger, silent_logger)
        .launched?(
          contaner_name,
          configuration: configuration,
          servers: servers,
        )
    end

    def compile(images:, skip_dependent:)
      Indocker::ImagesCompiler
        .new(Indocker.logger)
        .compile(
          configuration: configuration,
          image_list: images,
          skip_dependent: skip_dependent,
        )
    end

    def run(container_name, force_restart)
      Indocker::ContainerRunner
        .new(Indocker.logger)
        .run(
          configuration: configuration,
          container_name: container_name,
          force_restart: force_restart
        )
    end

    def global_build_args
      Indocker::ContextArgs.new(nil, configuration.global_build_args, nil)
    end

    def helper
      Indocker::BuildContextHelper.new(Indocker.configuration, nil)
    end

    def logger
      @logger ||= begin
        logger = if @log_level == Logger::DEBUG
          Logger.new(STDOUT)
        else
          Logger.new(File.open(File::NULL, "w"))
        end

        logger.level = @log_level || Logger::INFO

        logger.formatter = proc do |severity, datetime, progname, msg|
          level = Logger::SEV_LABEL.index(severity)

          severity = case level
          when Logger::INFO
            severity.green
          when Logger::WARN
            severity.purple
          when Logger::DEBUG
            severity.yellow
          when Logger::ERROR
            severity.red
          when Logger::FATAL
            severity.red
          else
            severity
          end

          severity = severity.downcase

          if logger.debug?
            if msg == "{timestamp}"
              ""
            else
              "#{datetime.strftime("%Y/%m/%d %H:%M:%S")} #{severity}: #{msg}\n"
            end
          else
            # Use a nicer logging for not debug
            if msg == "{timestamp}"
              datetime.strftime("%Y/%m/%d %H:%M:%S\n").grey
            else
              "  #{severity}: #{msg}\n"
            end
          end
        end

        logger
      end
    end

    def set_log_level(level)
      @log_level = level
    end

    def set_dockerignore(ignore_list)
      @dockerignore = ignore_list
    end

    def dockerignore
      @dockerignore || []
    end

    def build_helper(&proc)
      Indocker::BuildContextHelper.class_exec(&proc)
    end

    def set_configuration_name(name)
      @configuration_name = name
    end

    def configuration_name
      @configuration_name || (raise ArgumentError.new("configuration was not specified"))
    end
  end
end