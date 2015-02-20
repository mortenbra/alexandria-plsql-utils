create or replace package http_util_pkg
as

  /*
 
  Purpose:      Package contains HTTP utilities 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2008  Created
 
  */

  -- get clob from URL
  function get_clob_from_url (p_url in varchar2) return clob;

  -- get blob from URL
  function get_blob_from_url (p_url in varchar2) return blob;

end http_util_pkg;
/

