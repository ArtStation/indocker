require_relative './shell'

class Indocker::Docker
  class << self
    def build(image, build_args = '')
      Indocker::Shell.command_with_result("docker build #{build_args} --rm=true -t #{image} .", Indocker.logger)
    end

    def tag(image, tag)
      Indocker::Shell.command_with_result("docker tag #{image} #{tag}", Indocker.logger)
    end

    def push(tag)
      Indocker::Shell.command("docker push #{tag}", Indocker.logger)
    end

    def pull(url)
      Indocker::Shell.command("docker pull #{url}", Indocker.logger)
    end

    def stop(container_name, time: nil, skip_errors: false)
      time ||= 10 # default timeout for Linux
      Indocker::Shell.command("docker stop --time=#{time} #{container_name}", Indocker.logger, skip_errors: skip_errors)
      rm(container_name, skip_errors: skip_errors)
    end

    def rm(container_name, skip_errors: false)
      Indocker::Shell.command("docker rm -fv #{container_name}", Indocker.logger, skip_errors: skip_errors)
    end

    def run_command(image, args_list, command, service_args)
      extra_args = ""

      if service_args && service_args.is_a?(Hash)
        service_args.each do |arg, val|
          extra_args += " #{arg} #{val}"
        end
      end

      "docker run #{args_list} #{image} #{command} #{extra_args}"
    end

    def run(image, args_list, command,  service_args)
      Indocker::Shell.command(run_command(image, args_list, command, service_args), Indocker.logger)
    end

    def create_volume(name)
      res = Indocker::Shell.command_with_result("docker volume ls --filter \"name=^#{name}$\" --format \"{{.Name}}\"", Indocker.logger)
      volume_exist = !res.stdout.empty?

      if !volume_exist
        Indocker::Shell.command("docker volume create #{name}", Indocker.logger, skip_errors: true)
      end
    end

    def create_network(name)
      network_exist = false

      res = Indocker::Shell.command_with_result("docker network ls --filter \"name=^#{name}$\" --format \"{{.Name}}\"", Indocker.logger)
      network_exist = !res.stdout.empty?

      if !network_exist
        Indocker::Shell.command("docker network create #{name}", Indocker.logger, skip_errors: true)
      end
    end

    def image_id(image_url)
      command = "docker image inspect #{image_url} --format \"{{.Id}}\""

      res = Indocker::Shell.command_with_result(command, Indocker.logger)
      res.stdout
    end

    def container_id_by_name(container_name, only_healthy: false)
      health_args = if only_healthy
        '--filter="health=healthy"'
      end

      command = "docker ps -a #{health_args} --filter=\"status=running\" --filter \"name=#{container_name}$\" -q"

      id = nil

      res = Indocker::Shell.command_with_result(command, Indocker.logger)

      res.stdout.empty? ? nil : res.stdout
    end
  end
end
