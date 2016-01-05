
set scan off;


prompt Creating GOOGLE package specifications

@../ora/google_maps_pkg.pks
@../ora/google_maps_js_pkg.pks
@../ora/google_translate_pkg.pks

prompt Creating GOOGLE package bodies

@../ora/google_maps_pkg.pkb
@../ora/google_maps_js_pkg.pkb
@../ora/google_translate_pkg.pkb


prompt Done!

