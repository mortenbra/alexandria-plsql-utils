create or replace package body web_util_pkg
as
 
  /*
 
  Purpose:      Package contains various web-related utility routines
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.10.2011  Created
 
  */
 
 
function get_email_domain (p_email in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get domain name from email address
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.10.2011  Created
 
  */
  
  if instr(p_email, '@') > 0 then
    l_returnvalue := substr(p_email, instr(p_email, '@') + 1);
  end if;
  
  return l_returnvalue;
 
end get_email_domain;
 

function get_escaped_str_with_breaks (p_string in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      get escaped string with HTML line breaks
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.02.2012  Created
 
  */

  l_returnvalue := replace (htf.escape_sc(p_string), string_util_pkg.g_line_feed, '<br>');
 
  return l_returnvalue;
 
end get_escaped_str_with_breaks;


function get_local_file_url (p_file_path in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*
 
  Purpose:      get local file URL
 
  Remarks:      see http://kb.mozillazine.org/Links_to_local_pages_don't_work
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     27.08.2012  Created
 
  */
  
  -- "You (...) need to use proper URI syntax for local file references.
  -- It is not proper to enter an operating-system-specific path, such as c:\subdir\file.ext without converting it to a URI,
  -- which in this case would be file:///c:/subdir/file.ext.
  
  -- In general, a file path is converted to a URI by adding the scheme identifier file:,
  -- then three forward slashes (representing an empty authority or host segment),
  -- then the path with all backslashes converted to forward slashes.
  
  l_returnvalue := 'file:///' || replace(p_file_path, '\', '/');

  return l_returnvalue;

end get_local_file_url;


end web_util_pkg;
/
 


