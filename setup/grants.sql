
-- run as user SYS:

-- required for NTLM utilities
grant execute on dbms_crypto to &&your_schema;

-- Required for XLSX_BUILDER_PKG
grant execute on sys.utl_file to &&your_schema;
