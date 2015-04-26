create or replace package body datapump_util_pkg
as
 
  /*
 
  Purpose:      Package contains Data Pump utilities
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     04.11.2011  Created
 
  */
 
 
procedure export_schema_to_file (p_directory_name in varchar2,
                                 p_file_name in varchar2 := null,
                                 p_version in varchar2 := null,
                                 p_log_message in varchar2 := null,
                                 p_compress in boolean := false) 
as
  l_job_handle                   number;
  l_job_status                   varchar2(30); -- COMPLETED or STOPPED
  l_file_name                    varchar2(2000) := nvl(p_file_name, 'export_' || lower(user) || '_' || to_char(sysdate, 'yyyymmddhh24miss'));
begin
 
  /*
 
  Purpose:      export (current) schema to file
 
  Remarks:      the file name, if specified, should not include the extension, as it will be used for both dump and log files
                specify the p_version parameter if intending to import into an older database (such as '10.2' for XE)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     04.11.2011  Created
  MBR     07.08.2012  Added parameter to specify compression
 
  */
 
  l_job_handle := dbms_datapump.open ('EXPORT',  'SCHEMA', version => nvl(p_version, 'COMPATIBLE'));

  dbms_datapump.add_file (l_job_handle, l_file_name || '.dmp', p_directory_name);
  dbms_datapump.add_file (l_job_handle, l_file_name || '.log', p_directory_name, filetype => dbms_datapump.ku$_file_type_log_file);

  -- may set additional filters, not neccessary for full export of current schema
  -- see http://forums.oracle.com/forums/thread.jspa?messageID=9726231
  --dbms_datapump.metadata_filter (l_job_handle, 'SCHEMA_LIST', user);
  
  -- compression (note: p_version should be at least 11.1 to support this)
  if p_compress then
    dbms_datapump.set_parameter (l_job_handle, 'COMPRESSION', 'ALL');
  end if;
   
  dbms_datapump.start_job (l_job_handle);
 
  if p_log_message is not null then
    dbms_datapump.log_entry (l_job_handle, p_log_message);
  end if;

  dbms_datapump.wait_for_job (l_job_handle, l_job_status);
 
  dbms_datapump.detach (l_job_handle);

  debug_pkg.printf('Job status = %1, file name = %2', l_job_status, l_file_name);

  if l_job_status not in ('COMPLETED', 'STOPPED') then
    raise_application_error (-20000, string_util_pkg.get_str('The data pump job exited with status = %1 (file name = %2).', l_job_status, l_file_name));
  end if;
 
end export_schema_to_file;
 
 
procedure import_schema_from_file (p_directory_name in varchar2,
                                   p_file_name in varchar2,
                                   p_log_file_name in varchar2 := null,
                                   p_remap_from_schema in varchar2 := null,
                                   p_remap_to_schema in varchar2 := null,
                                   p_table_data_only in boolean := false) 
as

  l_job_handle                   number;
  l_job_status                   varchar2(30); -- COMPLETED or STOPPED
  
  l_from_schema                  varchar2(30) := nvl(p_remap_from_schema, user);
  l_to_schema                    varchar2(30) := nvl(p_remap_to_schema, user);

  l_log_file_name                varchar2(2000) := nvl(p_log_file_name, p_file_name || '_import_' || to_char(sysdate, 'yyyymmddhh24miss') || '.log');

begin
 
  /*
 
  Purpose:      import schema from file
 
  Remarks:      
  
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     04.11.2011  Created
 
  */
  
  l_job_handle := dbms_datapump.open ('IMPORT', 'SCHEMA');

  dbms_datapump.add_file (l_job_handle, p_file_name, p_directory_name);
  dbms_datapump.add_file (l_job_handle, l_log_file_name, p_directory_name, filetype => dbms_datapump.ku$_file_type_log_file);

  -- see http://download.oracle.com/docs/cd/B28359_01/server.111/b28319/dp_import.htm
  
  -- "If your dump file set does not contain the metadata necessary to create a schema, or if you do not have privileges, then the target schema must be created before the import operation is performed."
  -- "Nonprivileged users can perform schema remaps only if their schema is the target schema of the remap."

  if l_from_schema <> l_to_schema then
    dbms_datapump.metadata_remap (l_job_handle, 'REMAP_SCHEMA', l_from_schema, l_to_schema);
  end if;
  
  -- workaround for performance bug in 10.2, see http://forums.oracle.com/forums/thread.jspa?threadID=401886
  dbms_datapump.metadata_filter (l_job_handle, 'EXCLUDE_PATH_LIST', '''STATISTICS'''); -- note the double quotes

  if p_table_data_only then
    dbms_datapump.metadata_filter (l_job_handle, 'INCLUDE_PATH_LIST', '''TABLE'''); -- note the double quotes
    -- TODO: investigate the "TABLE_EXISTS_ACTION" parameter
    -- not sure what the context was for the TODO, but we use it to clear down tables before importing data.
    -- Usage is dbms_datapump.set_parameter(l_job_handle, 'TABLE_EXISTS_ACTION', 'TRUNCATE');
  end if;
  
  dbms_datapump.start_job (l_job_handle);
 
  dbms_datapump.wait_for_job (l_job_handle, l_job_status);
 
  dbms_datapump.detach (l_job_handle);

  if l_job_status in ('COMPLETED', 'STOPPED') then
    debug_pkg.printf ('SUCCESS: Job status %1, log file name %2', l_job_status, l_log_file_name);
  else
    debug_pkg.printf ('WARNING: The job exited with status %1, log file name %2', l_job_status, l_log_file_name);
  end if;
 
end import_schema_from_file;
 

end datapump_util_pkg;
/
 


