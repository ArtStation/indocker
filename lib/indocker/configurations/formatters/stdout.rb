class Indocker::Configurations::Formatters::Stdout
  def print(configuration)
    c = configuration
    <<~EOS
      Name: #{c.name}

      Repositories: {
      #{c.repositories.map do |alias_name, repository|
            "  #{alias_name}: #{repository.inspect}"
        end.join("\n")}
      }

      Registries: {
      #{c.registries.map do |alias_name, registry|
            "  #{alias_name}: #{registry.inspect}"
        end.join("\n")}
      }

      Servers: {
      #{c.servers.map do |alias_name, server|
            "  #{alias_name}: #{server.inspect}"
        end.join("\n")}
      }

      Build Servers: [
      #{c.build_servers.map do |build_server|
            "  #{build_server.inspect}"
        end.join("\n")}
      ]

      Tags: #{c.tags.inspect}

      Global build args: #{c.global_build_args.inspect}
    EOS
  end
end