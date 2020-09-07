class Indocker::DeploymentChecker
  def initialize(debug_logger, output_logger = nil)
    @debug_logger = debug_logger

    if output_logger
      @logger = output_logger
    else
      @logger = Logger.new(STDOUT)
      @logger.formatter = debug_logger.formatter
    end
  end

  def run(configuration:, servers:, only_containers: [])
    server_list = configuration.servers.map(&:name)

    server_list = servers.map do |server_name|
      server = configuration.servers.detect { |s| s.name == server_name }

      if !server
        @logger.error("Invalid server name specified :#{server_name} for configuration :#{configuration.name}")
        exit 1
      end

      server
    end

    if server_list.empty?
      server_list = configuration.servers
    end

    server_list = server_list.sort_by(&:name)

    @logger.info("Following servers will be checked:")

    server_list.each do |server|
      @logger.info("  - #{server.name}")
    end

    names_by_server = {}

    server_list.each do |server|
      names_by_server[server.name] = []
    end

    containers_by_server = Indocker
      .configuration
      .containers
      .select{ |container| only_containers.empty? || only_containers.include?(container.name) }
      .map do |container|
        (container.get_start_option(:scale) || 1).times do |number|
          container.servers.each do |server|
            names_by_server[server.name] << Indocker::ContainerHelper.hostname(configuration.name, container, number)
          end
        end
      end

    total_invalid_containers = []
    total_missing_containers = []
    
    server_list.each do |server|
      session = Indocker::SshSession.new(
        host: server.host,
        user: server.user,
        port: server.port,
        logger: @debug_logger
      )

      result = session.exec!('docker ps --filter="status=running" --format="{{.Names}}"')

      if !result.success?
        @logger.warn(result.stdout_data)
        @logger.warn(result.stderr_data)
        exit 1
      end

      names_list = result
        .stdout_data
        .strip
        .split("\n")

      invalid_containers = (names_list - names_by_server[server.name]).uniq

      total_invalid_containers += invalid_containers

      if !invalid_containers.empty?
        @logger.warn("EXTRA containers for server #{server.name.to_s.yellow}:")

        invalid_containers.each do |name|
          @logger.warn("  - #{name}")
        end
      end

      missing_containers = (names_by_server[server.name] - names_list).uniq
      missing_containers = missing_containers.select do |name|
        !(name.include?('migrations') || name.include?('gems_installer'))
      end

      total_missing_containers += missing_containers

      if !missing_containers.empty?
        @logger.warn("MISSING CONTAINERS for server #{server.name.to_s.yellow}:")

        missing_containers.each do |name|
          @logger.warn("  - #{name}")
        end
      end
    end

    { missing_containers: total_missing_containers, invalid_containers: total_invalid_containers }
  end

  def launched?(container_name, configuration:, servers: nil)
    container = Indocker.containers.detect { |c| c.name == container_name.to_sym }
    hostnames = (container.get_start_option(:scale) || 1).times.map do |number|
      Indocker::ContainerHelper.hostname(configuration.name, container, number)
    end

    servers ||= container.servers.map(&:name)

    result = run(configuration: configuration, servers: container.servers.map(&:name), only_containers: [container.name])
    result[:missing_containers].empty?
  end
end
