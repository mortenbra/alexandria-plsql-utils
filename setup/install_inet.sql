
set scan off;

prompt Creating INET package specifications

@../ora/flex_ws_api.pks
@../ora/ftp_util_pkg.pks
@../ora/html_util_pkg.pks
@../ora/http_util_pkg.pks
@../ora/icalendar_util_pkg.pks
@../ora/json_util_pkg.pks
@../ora/rss_util_pkg.pks
@../ora/t_soap_envelope.pks
@../ora/web_util_pkg.pks

prompt Creating INET package bodies

@../ora/flex_ws_api.pkb
@../ora/ftp_util_pkg.pkb
@../ora/html_util_pkg.pkb
@../ora/http_util_pkg.pkb
@../ora/icalendar_util_pkg.pkb
@../ora/json_util_pkg.pkb
@../ora/rss_util_pkg.pkb
@../ora/t_soap_envelope.pkb
@../ora/web_util_pkg.pkb


prompt Done!

