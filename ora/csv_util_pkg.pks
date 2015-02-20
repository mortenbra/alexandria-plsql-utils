create or replace package csv_util_pkg
as
 
  /*
 
  Purpose:      Package handles comma-separated values (CSV)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     31.03.2010  Created
 
  */
  
  g_default_separator            constant varchar2(1) := ',';
 
 
  -- convert CSV line to array of values
  function csv_to_array (p_csv_line in varchar2,
                         p_separator in varchar2 := g_default_separator) return t_str_array;
 
  -- convert array of values to CSV
  function array_to_csv (p_values in t_str_array,
                         p_separator in varchar2 := g_default_separator) return varchar2;
 
  -- get value from array by position
  function get_array_value (p_values in t_str_array,
                            p_position in number,
                            p_column_name in varchar2 := null) return varchar2;

  -- convert clob to CSV
  function clob_to_csv (p_csv_clob in clob,
                        p_separator in varchar2 := g_default_separator,
                        p_skip_rows in number := 0) return t_csv_tab pipelined;

end csv_util_pkg;
/

