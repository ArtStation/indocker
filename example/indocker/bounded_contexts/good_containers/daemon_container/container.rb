Indocker
  .define_container(:daemon_container)
  .tags('daemon_container', 'console=true')
  .image(:daemon_container)
  .networks(:app_net)
  .daemonize(true)