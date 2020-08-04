Indocker
  .define_container(:container_failing_build)
  .tags('container_failing_build', 'console=true')
  .image(:container_failing_build)
  .networks(:app_net)