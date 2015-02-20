create or replace package plsql_status_web_pkg
as

  /*

  Purpose:    Package provides a dynamic RSS feed of PL/SQL compilation status/errors

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */

  -- list errors
  procedure rss;
  
  -- show details
  procedure show (p_type in varchar2,
                  p_name in varchar2,
                  p_seq in number);
                  
  -- main page
  procedure home;
  

end plsql_status_web_pkg;
/

