Indocker
  .define_container(:ruby)
  .tags('ruby', 'console=true')
  .image(:ruby)
  .networks(:app_net)
  .daemonize(false)