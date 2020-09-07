Indocker
  .define_container(:good_container)
  .depends_on(:dependency_container)
  .tags('good_container', 'console=true')
  .image(:good_container)
  .networks(:app_net)
  .daemonize(false)
  # .start({
  #   env_files: [:default_env],
  # })