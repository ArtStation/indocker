Indocker
  .define_image(:good_container)
  .depends_on(:parent_image)
  .registry(:default)