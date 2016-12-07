
set scan off;

prompt Creating types

@@types.sql

prompt Creating package specifications

@../ora/amazon_aws_auth_pkg.pks
@../ora/amazon_aws_s3_pkg.pks
@../ora/apex_util_pkg.pks
@../ora/crypto_util_pkg.pks
@../ora/csv_util_pkg.pks
@../ora/datapump_util_pkg.pks
@../ora/date_util_pkg.pks
@../ora/debug_pkg.pks
@../ora/encode_util_pkg.pks
@../ora/file_util_pkg.pks
@../ora/flex_ws_api.pks
@../ora/ftp_util_pkg.pks
@../ora/gis_util_pkg.pks
@../ora/google_maps_pkg.pks
@../ora/google_maps_js_pkg.pks
@../ora/google_translate_pkg.pks
@../ora/html_util_pkg.pks
@../ora/http_util_pkg.pks
@../ora/icalendar_util_pkg.pks
@../ora/image_util_pkg.pks
@../ora/json_util_pkg.pks
@../ora/math_util_pkg.pks
@../ora/ms_ews_util_pkg.pks
@../ora/ntlm_util_pkg.pks
@../ora/ntlm_http_pkg.pks
@../ora/ooxml_util_pkg.pks
@../ora/owa_util_pkg.pks
@../ora/paypal_util_pkg.pks
@../ora/pdf_builder_pkg.pks
@../ora/random_util_pkg.pks
@../ora/raw_util_pkg.pks
@../ora/regexp_util_pkg.pks
@../ora/rss_util_pkg.pks
@../ora/sms_util_pkg.pks
@../ora/soap_server_pkg.pks
@../ora/sql_builder_pkg.pks
@../ora/sql_util_pkg.pks
@../ora/string_util_pkg.pks
@../ora/sylk_util_pkg.pks
@../ora/t_soap_envelope.pks
@../ora/uri_template_util_pkg.pks
@../ora/validation_util_pkg.pks
@../ora/web_util_pkg.pks
@../ora/xlsx_builder_pkg.pks
@../ora/xml_builder_pkg.pks
@../ora/xml_dataset_pkg.pks
@../ora/xml_stylesheet_pkg.pks
@../ora/xml_util_pkg.pks
@../ora/zip_util_pkg.pks

prompt Creating package bodies

@../ora/amazon_aws_auth_pkg.pkb
@../ora/amazon_aws_s3_pkg.pkb
@../ora/apex_util_pkg.pkb
@../ora/crypto_util_pkg.pkb
@../ora/csv_util_pkg.pkb
@../ora/datapump_util_pkg.pkb
@../ora/date_util_pkg.pkb
@../ora/debug_pkg.pkb
@../ora/encode_util_pkg.pkb
@../ora/file_util_pkg.pkb
@../ora/flex_ws_api.pkb
@../ora/ftp_util_pkg.pkb
@../ora/gis_util_pkg.pkb
@../ora/google_maps_pkg.pkb
@../ora/google_maps_js_pkg.pkb
@../ora/google_translate_pkg.pkb
@../ora/html_util_pkg.pkb
@../ora/http_util_pkg.pkb
@../ora/icalendar_util_pkg.pkb
@../ora/image_util_pkg.pkb
@../ora/json_util_pkg.pkb
@../ora/math_util_pkg.pkb
@../ora/ms_ews_util_pkg.pkb
@../ora/ntlm_util_pkg.pkb
@../ora/ntlm_http_pkg.pkb
@../ora/ooxml_util_pkg.pkb
@../ora/owa_util_pkg.pkb
@../ora/paypal_util_pkg.pkb
@../ora/pdf_builder_pkg.pkb
@../ora/random_util_pkg.pkb
@../ora/raw_util_pkg.pkb
@../ora/regexp_util_pkg.pkb
@../ora/rss_util_pkg.pkb
@../ora/sms_util_pkg.pkb
@../ora/soap_server_pkg.pkb
@../ora/sql_builder_pkg.pkb
@../ora/sql_util_pkg.pkb
@../ora/string_util_pkg.pkb
@../ora/sylk_util_pkg.pkb
@../ora/t_soap_envelope.pkb
@../ora/uri_template_util_pkg.pkb
@../ora/validation_util_pkg.pkb
@../ora/web_util_pkg.pkb
@../ora/xlsx_builder_pkg.pkb
@../ora/xml_builder_pkg.pkb
@../ora/xml_dataset_pkg.pkb
@../ora/xml_stylesheet_pkg.pkb
@../ora/xml_util_pkg.pkb
@../ora/zip_util_pkg.pkb


prompt Done!

