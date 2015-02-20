create or replace package body owa_util_pkg
as
 
  /*
 
  Purpose:      Package contains utilities related to PL/SQL Web Toolkit (OWA)
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     12.06.2008  Created
 
  */


procedure htp_print_clob (p_clob in clob,
                          p_add_newline in boolean := true)
as
  l_buffer   varchar2(32767);
  l_max_size constant integer := 8000;
  l_start    integer := 1;
  l_cloblen  integer; 
begin

  /*

  Purpose:    print clob to HTTP buffer

  Remarks:    from http://francis.blog-city.com/ora20103_null_input_is_not_allowed.htm

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.01.2009  Created

  */
  
  if p_clob is not null then
  
    l_cloblen := dbms_lob.getlength (p_clob );
  
    loop
      l_buffer := dbms_lob.substr (p_clob, l_max_size, l_start);
      htp.prn (l_buffer);
      l_start := l_start + l_max_size;
      exit when l_start > l_cloblen;
    end loop ;
  
    if p_add_newline then
      htp.p;
    end if;  
    
  end if;

end htp_print_clob;


procedure htp_printf (p_str in varchar2,
                      p_value1 in varchar2 := null,
                      p_value2 in varchar2 := null,
                      p_value3 in varchar2 := null,
                      p_value4 in varchar2 := null,
                      p_value5 in varchar2 := null,
                      p_value6 in varchar2 := null,
                      p_value7 in varchar2 := null,
                      p_value8 in varchar2 := null)
as
begin

  /*

  Purpose:    print string with substitution values to HTTP buffer

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     06.02.2011  Created

  */

  htp.p(string_util_pkg.get_str(p_str, p_value1, p_value2, p_value3, p_value4, p_value5, p_value6, p_value7, p_value8));

end htp_printf;



procedure init_owa (p_names in owa.vc_arr := g_empty_vc_arr,
                    p_values in owa.vc_arr := g_empty_vc_arr)
as
  l_version                      pls_integer;
  l_names                        owa.vc_arr := p_names;
  l_values                       owa.vc_arr := p_values;
begin

  /*

  Purpose:    initialize OWA environment

  Remarks:    all gateways (mod_plsql, DBMS_EPG, Apex Listener, Thoth Gateway, etc.)
              will do this automatically before a procedure is invoked via a web server
              
              but this is useful (and required) for calling web procedures via sqlplus or other (non-gateway) tools 
              
              see http://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:347617533333

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */

  l_version := owa.initialize;

  if l_names.count = 0 then
    l_names(1) := 'PLSQL_GATEWAY';
    l_values(1) := 'Dummy Gateway';
    l_names(2) := 'GATEWAY_IVERSION';
    l_values(2) := '2';     
    l_names(3) := 'HTTP_USER_AGENT';
    l_values(3) := 'Mozilla/5.0 (compatible); SQL*Plus';
    l_names(4) := 'REQUEST_CHARSET';
    l_values(4) := 'AL32UTF8';
    l_names(5) := 'REQUEST_IANA_CHARSET';
    l_values(5) := 'UTF-8';
  end if;

  owa.init_cgi_env(l_names.count, l_names, l_values);

  htp.init;
  htp.htbuf_len := 63;


end init_owa;
                          

function get_page (p_include_headers in boolean := true) return clob
as
  l_page        htp.htbuf_arr;
  l_lines       pls_integer := 99999999;
  l_returnvalue clob;
begin

  /*

  Purpose:    get page from HTTP buffer

  Remarks:    see http://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:347617533333

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created
  MBR     20.03.2011  Added option to exclude headers

  */
  
  owa.get_page (l_page, l_lines);

  for i in 1 .. l_lines loop
    l_returnvalue := l_returnvalue || l_page(i);
  end loop;  

  if (not p_include_headers) then
    l_returnvalue := substr(l_returnvalue, instr(l_returnvalue, owa.nl_char || owa.nl_char));
  end if;

  return l_returnvalue;

end get_page;


function is_user_agent_ie return boolean
as
  l_returnvalue boolean;
begin

  /*

  Purpose:    is user agent Internet Explorer ?

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     27.02.2012  Created

  */

  l_returnvalue := instr(owa_util.get_cgi_env('HTTP_USER_AGENT'), ' MSIE ') > 0;

  return l_returnvalue;

end is_user_agent_ie;


procedure download_file (p_file in blob,
                         p_mime_type in varchar2,
                         p_file_name in varchar2,
                         p_expires in date := null)
as
  l_file blob := p_file; -- need a local copy as wpg_docload.download_file uses an IN OUT parameter
begin

  /*

  Purpose:    download file

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     23.09.2012  Created

  */

  owa_util.mime_header(nvl(p_mime_type, 'application/octet'), false);
  htp.p('Content-length: ' || dbms_lob.getlength(p_file));
  if p_expires is not null then
    htp.p('Expires:' || to_char(p_expires, 'FMDy, DD Month YYYY HH24:MI:SS') || 'GMT');
  end if;
  htp.p('Content-Disposition: attachment; filename="' || nvl(p_file_name, 'untitled') || '"');
  owa_util.http_header_close;
    
  wpg_docload.download_file (l_file);

end download_file;


end owa_util_pkg;
/
