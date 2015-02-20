
-- monitor jobs

select *
from dba_datapump_jobs;

select *
from dba_datapump_sessions;


-- export current schema to file, use default file name, and make the export compatible with XE 10g
-- include a custom message

begin
  debug_pkg.debug_on;
  datapump_util_pkg.export_schema_to_file ('DEVTEST_TEMP_DIR', p_version => '10.2', p_log_message => 'it is possible to include custom messages in the log');
end;
/

-- import dump file to backup schema

begin
  debug_pkg.debug_on;
  datapump_util_pkg.import_schema_from_file ('DEVTEST_TEMP_DIR', 'export_111105183000.dmp', p_remap_to_schema => 'DEVTEST_BACKUP');
end;
/

