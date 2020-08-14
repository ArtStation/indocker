Indocker
  .define_container(:bad_container_build)
  .tags('bad_container_build', 'console=true')
  .image(:bad_container_build)
  .networks(:app_net)
  .daemonize(false)