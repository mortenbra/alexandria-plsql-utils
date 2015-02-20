create or replace package body plsql_status_web_pkg
as

  /*

  Purpose:    Package provides a dynamic RSS feed of PL/SQL compilation status/errors

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */
  
  g_package_name                 constant varchar2(30)  := 'plsql_status_web_pkg';
  g_host_name                    constant varchar2(255) := owa_util.get_cgi_env('HTTP_HOST');
  g_service_path                 constant varchar2(255) := owa_util.get_owa_service_path;

function get_errors return sys_refcursor
as
  l_returnvalue sys_refcursor;
begin

  /*

  Purpose:    query to get errors in schema

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */

  open l_returnvalue
  for
  select null as id,
    name || ': ' || substr(text,1,100) as title,
    attribute || ': ' || text as description,
    'http://' || g_host_name || g_service_path || g_package_name || '.show?p_type=' || type || '&amp;p_name=' || name || '&amp;p_seq=' || sequence as link,
    sysdate as updated_on
  from user_errors
  order by type, name, sequence; 

  return l_returnvalue;

end get_errors;


procedure rss
as
  l_cursor        sys_refcursor;
  l_rss           clob;
begin

  /*

  Purpose:    generate the RSS feed

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */
  
  l_cursor := get_errors;

  l_rss := rss_util_pkg.ref_cursor_to_feed (l_cursor, 'PL/SQL Errors', 'This is a feed of compilation errors in the database schema.');
  
  owa_util.mime_header('application/xml', false);
  owa_util.http_header_close;
  
  owa_util_pkg.htp_print_clob (l_rss);
  
end rss;



procedure show (p_type in varchar2,
                p_name in varchar2,
                p_seq in number)
as
  l_error  user_errors%rowtype;
  l_object user_objects%rowtype;
begin

  /*

  Purpose:    print details for specific error

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */

  begin
    select *
    into l_error
    from user_errors
    where type = p_type
    and name = p_name
    and sequence = p_seq;
  exception
    when no_data_found then
      l_error := null;
  end;
  
  begin
    select *
    into l_object
    from user_objects
    where object_type = l_error.type
    and object_name = l_error.name;
  exception
    when no_data_found then
      l_object := null;
  end;  
  
  htp.p('<title>Error Details</title><style>
    * { font-family: tahoma; }
    div.errormsg { border: 1px solid black; background-color:orange; font-size: 18px; font-weight: bold; width: 75%; margin-top: 10px; margin-bottom: 10px; padding: 20px; }
    div.code { border: 1px dotted #999999; background-color: #dddddd; width: 75%; margin-top: 10px; margin-bottom: 10px; padding: 20px;  }
    pre, pre b { font-family: lucida console, courier new, courier; font-size: 13px; }
    b.error_line { border: 1px dotted red; background-color: pink;  }
    a { padding: 3px; border: 1px dotted #999999; }
    div.credits { font-size: 9px; }
  </style>');

  htp.header (1, l_error.name || ' (' || l_error.type || ')');

  if (l_object.object_name is not null) then
    htp.p('Status: <b>' || l_object.status || '</b>, Created: ' || apex_util.get_since (l_object.created) || ', Last Modified: ' || apex_util.get_since (l_object.last_ddl_time) || ', Timestamp: ' || l_object.timestamp);
  end if;

  htp.p ('<div class="errormsg">' || l_error.attribute || ': ' || l_error.text || '</div>');

  htp.prn('Search for this error on ');
  htp.anchor('http://www.google.com/search?q=' || utl_url.escape (l_error.text), 'Google');
  htp.prn(' ');
  htp.anchor('http://www.oracle.com/pls/db102/search?remark=advanced_search&word=' || utl_url.escape (l_error.text), 'Oracle Docs');
  htp.prn(' ');
  htp.anchor('http://forums.oracle.com/forums/search.jspa?q=' || utl_url.escape (l_error.text), 'Oracle Forums');
  htp.prn(' ');
  htp.anchor('http://asktom.oracle.com/pls/ask/search?p_string=' || utl_url.escape (l_error.text), 'AskTom');
  htp.prn(' ');
  htp.anchor('http://stackoverflow.com/search?q=' || utl_url.escape (l_error.text), 'StackOverflow');
  
  
  
  if l_error.line <> 0 then
  
    htp.p('<div class="code"><pre>');
    for l_rec in (select line, replace(text, chr(10), '') as text from user_source where type = p_type and name = p_name and line between l_error.line - 20 and l_error.line + 20 order by line) loop
      
      if l_rec.line = l_error.line then
        htp.p('<b class="error_line">' || lpad(l_rec.line, 3, ' ') || ' ' || l_rec.text || '</b>');
      else
        htp.p(lpad(l_rec.line, 4, ' ') || ' ' || l_rec.text);
      end if; 
    
    end loop;
    htp.p('</pre></div>');
  
  end if;
  
  htp.p('<hr><div class="credits">This is a sample from the free, open source <a href="http://code.google.com/p/plsql-utils/">PL/SQL Utility Library</a>.</div>');


end show;


procedure home
as
begin

  /*

  Purpose:    Main page

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */

  htp.p('<h1>Welcome</h1>');

  htp.p('<a href="' || g_package_name || '.rss">Get the RSS feed here</a>');

end home;




end plsql_status_web_pkg;
/

