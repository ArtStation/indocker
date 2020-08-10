Indocker
  .define_container(:good_container)
  .tags('good_container', 'console=true')
  .image(:good_container)
  .networks(:app_net)