CREATE OR REPLACE package html_util_pkg
as

  /*

  Purpose:    Package contains HTML utilities

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.12.2009  Created

  */
  
  -- replace normal line breaks with html line breaks
  function get_html_with_line_breaks (p_html in varchar2) return varchar2;
  
  -- make URLs in text into hyperlinks
  function add_hyperlinks (p_text in varchar2,
                           p_class in varchar2 := null) return varchar2;
  
  -- make URLs in text into hyperlinks
  function add_hyperlinks (p_text in clob,
                           p_class in varchar2 := null) return clob;

end html_util_pkg;
/
