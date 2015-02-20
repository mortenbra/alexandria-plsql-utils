create or replace package body http_util_pkg
as

  /*
 
  Purpose:      Package contains HTTP utilities 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2008  Created
 
  */


function get_clob_from_url (p_url in varchar2) return clob
as
  l_http_request   utl_http.req;
  l_http_response  utl_http.resp;
  l_text           varchar2(32767);
  l_returnvalue    clob;

begin


  /*
 
  Purpose:      get clob from URL 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2008  Created
 
  */

  dbms_lob.createtemporary(l_returnvalue, false);

  l_http_request  := utl_http.begin_request (p_url);
  l_http_response := utl_http.get_response (l_http_request);

  begin
    loop
      utl_http.read_text (l_http_response, l_text, 32767);
      dbms_lob.writeappend (l_returnvalue, length(l_text), l_text);
    end loop;
  exception
    when utl_http.end_of_body then
      utl_http.end_response (l_http_response);
  end;
  
  return l_returnvalue;

exception
  when others then
    utl_http.end_response (l_http_response);
    dbms_lob.freetemporary(l_returnvalue);
    raise;

end get_clob_from_url;


function get_blob_from_url (p_url in varchar2) return blob
as
  l_http_request   utl_http.req;
  l_http_response  utl_http.resp;
  l_raw            raw(32767);
  l_returnvalue    blob;

begin

  /*
 
  Purpose:      Get blob from URL 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2008  Created
 
  */

  dbms_lob.createtemporary (l_returnvalue, false);

  l_http_request  := utl_http.begin_request (p_url);
  l_http_response := utl_http.get_response (l_http_request);

  begin
    loop
      utl_http.read_raw(l_http_response, l_raw, 32767);
      dbms_lob.writeappend (l_returnvalue, utl_raw.length(l_raw), l_raw);
    end loop;
  exception
    when utl_http.end_of_body then
      utl_http.end_response(l_http_response);
  end;

  return l_returnvalue;

exception
  when others then
    utl_http.end_response (l_http_response);
    dbms_lob.freetemporary (l_returnvalue);
    raise;

end get_blob_from_url;


end http_util_pkg;
/

