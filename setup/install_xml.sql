
set scan off;


prompt Creating XML package specifications

@../ora/xml_builder_pkg.pks
@../ora/xml_dataset_pkg.pks
@../ora/xml_stylesheet_pkg.pks

prompt Creating XML package bodies

@../ora/xml_builder_pkg.pkb
@../ora/xml_dataset_pkg.pkb
@../ora/xml_stylesheet_pkg.pkb


prompt Done!

