create or replace package datapump_util_pkg
as
 
  /*
 
  Purpose:      Package contains Data Pump utilities
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     04.11.2011  Created
 
  */
 
 
  -- export (current) schema to file
  procedure export_schema_to_file (p_directory_name in varchar2,
                                   p_file_name in varchar2 := null,
                                   p_version in varchar2 := null,
                                   p_log_message in varchar2 := null,
                                   p_compress in boolean := false);
 
  -- import schema from file
  procedure import_schema_from_file (p_directory_name in varchar2,
                                     p_file_name in varchar2,
                                     p_log_file_name in varchar2 := null,
                                     p_remap_from_schema in varchar2 := null,
                                     p_remap_to_schema in varchar2 := null,
                                     p_table_data_only in boolean := false);
 
 
end datapump_util_pkg;
/

