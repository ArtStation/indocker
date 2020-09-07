Indocker
  .define_image(:daemon_container)
  .depends_on(:parent_image)
  .registry(:default)