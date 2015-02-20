create or replace package sql_util_pkg
as

  /*

  Purpose:    Package contains various SQL utilities

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     01.01.2008  Created
  
  */

  -- make specified number of rows
  function make_rows (p_number_of_rows in number) return t_num_array pipelined;

  -- make rows between interval
  function make_rows (p_start_with in number,
                      p_end_with in number) return t_num_array pipelined;

  -- convert clob to blob
  function clob_to_blob (p_clob in clob) return blob;
  
  -- convert blob to clob
  function blob_to_clob (p_blob in blob) return clob;

end sql_util_pkg;
/

