create or replace package json_util_pkg
as

  /*

  Purpose:    JSON utilities for PL/SQL

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.01.2010  Created
  
  */

  -- generate JSON from REF Cursor
  function ref_cursor_to_json (p_ref_cursor in sys_refcursor,
                               p_max_rows in number := null,
                               p_skip_rows in number := null) return clob;

  -- generate JSON from SQL statement
  function sql_to_json (p_sql in varchar2,
                        p_param_names in t_str_array := null,
                        p_param_values in t_str_array := null,
                        p_max_rows in number := null,
                        p_skip_rows in number := null) return clob;


end json_util_pkg;
/

