
set scan off;

prompt Creating CORE types

@@types.sql

prompt Creating CORE package specifications

@../ora/crypto_util_pkg.pks
@../ora/date_util_pkg.pks
@../ora/debug_pkg.pks
@../ora/encode_util_pkg.pks
@../ora/file_util_pkg.pks
@../ora/math_util_pkg.pks
@../ora/random_util_pkg.pks
@../ora/raw_util_pkg.pks
@../ora/regexp_util_pkg.pks
@../ora/sql_util_pkg.pks
@../ora/string_util_pkg.pks
@../ora/xml_util_pkg.pks
@../ora/zip_util_pkg.pks

prompt Creating CORE package bodies

@../ora/crypto_util_pkg.pkb
@../ora/date_util_pkg.pkb
@../ora/debug_pkg.pkb
@../ora/encode_util_pkg.pkb
@../ora/file_util_pkg.pkb
@../ora/math_util_pkg.pkb
@../ora/random_util_pkg.pkb
@../ora/raw_util_pkg.pkb
@../ora/regexp_util_pkg.pkb
@../ora/sql_util_pkg.pkb
@../ora/string_util_pkg.pkb
@../ora/xml_util_pkg.pkb
@../ora/zip_util_pkg.pkb


prompt Done!

