Indocker
  .define_container(:dependency_container)
  .tags('dependency_container', 'console=true')
  .image(:dependency_container)
  .networks(:app_net)
  .daemonize(false)