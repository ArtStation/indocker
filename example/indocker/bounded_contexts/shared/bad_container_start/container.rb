Indocker
  .define_container(:bad_container_start)
  .tags('bad_container_start', 'console=true')
  .image(:bad_container_start)
  .networks(:app_net)