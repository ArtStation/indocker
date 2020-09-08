Indocker
  .build_configuration(:external)
  .use_registry(:dev, as: :default)
  .use_build_server(:external_bs)
  .global_build_args({
    domain: 'indocker.me',
  })
  .use_env_file(:development_env, as: :default_env)
  .enabled_containers(
    ruby: {
      servers: [:external],
    },
    good_container: {
      servers: [:external],
    },
    bad_container_build: {
      servers: [:external],
    },
    bad_container_start: {
      servers: [:external],
    },
    daemon_container: {
      servers: [:external],
    }
  ).artifacts(
    indocker_readme: [:external],
    hosts_file: [:external],
  )