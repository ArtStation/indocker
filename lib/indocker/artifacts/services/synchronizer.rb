class Indocker::Artifacts::Services::Synchronizer
  def initialize(logger:)
    @logger = logger
  end

  def call(clonner, artifact_servers)
    @logger.info("Syncing git artifacts")

    remote_operations = []

    artifact_servers.each do |artifact, servers|
      remote_operations += servers.map do |server|
        @progress.start_syncing_artifact(server, artifact)

        thread = Thread.new do
          server.synchronize do
            session = Indocker::SshSession.new(
              host: server.host,
              user: server.user,
              port: server.port,
              logger: @logger
            )

            if artifact.is_git?
              @logger.info("Pulling git artifact  #{artifact.name.to_s.green} for #{server.user}@#{server.host}")
              result = clonner.clone(session, artifact.repository)

              if result.exit_code != 0
                @logger.error("Artifact repository :#{artifact.repository.name} was not clonned")
                @logger.error(result.stderr_data)
                exit 1
              end
            end

            artifact.files.each do |artifact_item|
              result = session.exec!("mkdir -p #{target_path}")
              result = session.exec!("cp -r #{artifact_item.source_path} #{artifact_item.target_path}")

              if !result.success?
                @logger.error(result.stdout_data)
                @logger.error(result.stderr_data)
                exit 1
              end
            end

            @progress.finish_syncing_artifact(server, artifact)
          end
        end

        RemoteOperation.new(thread, server, :artifact_sync)
      end
    end

    remote_operations
  end
end