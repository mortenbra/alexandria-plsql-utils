create or replace package sys.utl_file_nonstandard
as

  /*

  Purpose:    Package contains functionality missing from the standard UTL_FILE package

  Remarks:    This package MUST be created in the SYS schema due to a dependency on an X$ table
              See http://www.chrispoole.co.uk/tips/plsqltip2.htm

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.07.2011  Created
  
  */

  type t_file_list is table of varchar2(4000) index by binary_integer;

  -- get list of files in directory
  function get_file_list (p_directory_name in varchar2,
                          p_file_pattern in varchar2 := null,
                          p_max_files in number := null) return t_file_list;

end utl_file_nonstandard;
/

