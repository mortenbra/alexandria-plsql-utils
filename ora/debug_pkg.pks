create or replace package debug_pkg
as

  /*

  Purpose:    The package handles debug information

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  -- turn off debugging
  procedure debug_off;

  -- turn on debugging
  procedure debug_on;

  -- print debug information
  procedure print (p_msg in varchar2);

  -- print debug information (name/value pair)
  procedure print (p_msg in varchar2,
                   p_value in varchar2);

  -- print debug information (number)
  procedure print (p_msg in varchar2,
                   p_value in number);

  -- print debug information (date)
  procedure print (p_msg in varchar2,
                   p_value in date);
                   
  -- print debug information (boolean)
  procedure print (p_msg in varchar2,
                   p_value in boolean);
  
  -- print debug information (ref cursor)
  procedure print (p_refcursor in sys_refcursor,
                   p_null_handling in number := 0);

  -- print debug information (xmltype)
  procedure print (p_xml in xmltype);

  -- print debug information (clob)
  procedure print (p_clob in clob);

  -- print debug information (multiple values)
  procedure printf (p_msg in varchar2,
                    p_value1 in varchar2 := null,
                    p_value2 in varchar2 := null,
                    p_value3 in varchar2 := null,
                    p_value4 in varchar2 := null,
                    p_value5 in varchar2 := null,
                    p_value6 in varchar2 := null,
                    p_value7 in varchar2 := null,
                    p_value8 in varchar2 := null);

  -- get date string in debug format
  function get_fdate(p_date in date) return varchar2;
  
  -- set session info (will be available in v$session)
  procedure set_info (p_action in varchar2,
                      p_module in varchar2 := null);

  -- clear session info
  procedure clear_info;

end debug_pkg;
/

