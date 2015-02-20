create or replace package owa_util_pkg
as
 
  /*
 
  Purpose:      Package contains utilities related to PL/SQL Web Toolkit (OWA)
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     12.06.2008  Created
 
  */
  
  g_empty_vc_arr                 owa.vc_arr;

  -- print clob to HTTP buffer
  procedure htp_print_clob (p_clob in clob,
                            p_add_newline in boolean := true);

  -- print string with substitution values to HTTP buffer
  procedure htp_printf (p_str in varchar2,
                        p_value1 in varchar2 := null,
                        p_value2 in varchar2 := null,
                        p_value3 in varchar2 := null,
                        p_value4 in varchar2 := null,
                        p_value5 in varchar2 := null,
                        p_value6 in varchar2 := null,
                        p_value7 in varchar2 := null,
                        p_value8 in varchar2 := null);

  -- initialize OWA environment
  procedure init_owa (p_names in owa.vc_arr := g_empty_vc_arr,
                      p_values in owa.vc_arr := g_empty_vc_arr);
                          
  -- get page from HTTP buffer
  function get_page (p_include_headers in boolean := true) return clob;

  -- is user agent Internet Explorer ?
  function is_user_agent_ie return boolean;

  -- download file
  procedure download_file (p_file in blob,
                           p_mime_type in varchar2,
                           p_file_name in varchar2,
                           p_expires in date := null);
  
end owa_util_pkg;
/
 
