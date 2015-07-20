
set scan off;

prompt Creating MICROSOFT package specifications

@../ora/ms_ews_util_pkg.pks
@../ora/ntlm_util_pkg.pks
@../ora/ntlm_http_pkg.pks
@../ora/ooxml_util_pkg.pks
@../ora/xlsx_builder_pkg.pks
@../ora/xml_stylesheet_pkg.pks

prompt Creating MICROSOFT package bodies

@../ora/ms_ews_util_pkg.pkb
@../ora/ntlm_util_pkg.pkb
@../ora/ntlm_http_pkg.pkb
@../ora/ooxml_util_pkg.pkb
@../ora/xlsx_builder_pkg.pkb
@../ora/xml_stylesheet_pkg.pkb

prompt Done!

