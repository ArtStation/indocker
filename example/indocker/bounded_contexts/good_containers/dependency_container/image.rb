Indocker
  .define_image(:dependency_container)
  .depends_on(:parent_image)
  .registry(:default)