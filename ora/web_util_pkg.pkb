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
 

function get_escaped_str_with_breaks (p_string in varchar2,
                                      p_escape_text_if_markup in boolean := true) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      get escaped string with HTML line breaks
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.02.2012  Created
  MBR     21.05.2015  Option to skip escaping if text already contains markup
 
  */

  if (not p_escape_text_if_markup) and (text_contains_markup (p_string)) then
    l_returnvalue := p_string;
  else
    l_returnvalue := replace (htf.escape_sc(p_string), string_util_pkg.g_line_feed, '<br>');
  end if;
 
  return l_returnvalue;
 
end get_escaped_str_with_breaks;


function get_escaped_str_with_paragraph (p_string in varchar2,
                                         p_escape_text_if_markup in boolean := true,
                                         p_encode_asterisks in boolean := false,
                                         p_linkify_text in boolean := false) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      get escaped string with HTML paragraphs
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     27.10.2013  Created
  MBR     14.12.2014  Option to encode asterisks with HTML entity
  MBR     21.05.2015  Option to skip escaping if text already contains markup
  MBR     29.05.2016  Option to linkify text
  MBR     13.06.2016  Linkify: Fix for links at the end of line/paragraph
 
  */

  if (not p_escape_text_if_markup) and (text_contains_markup (p_string)) then
    l_returnvalue := p_string;
  else
    l_returnvalue := replace (p_string, string_util_pkg.g_carriage_return, '');
    l_returnvalue := replace (htf.escape_sc (l_returnvalue), string_util_pkg.g_line_feed, '</p><p>');
    l_returnvalue := '<p>' || l_returnvalue || '</p>';
    -- remove empty paragraphs
    l_returnvalue := replace (l_returnvalue, '<p></p>', '');
  end if;

  if p_encode_asterisks then
    l_returnvalue := replace (l_returnvalue, '*', chr(38) || 'bull;');
  end if;

  if p_linkify_text then
    l_returnvalue := linkify_text (replace(l_returnvalue, '</p>', ' </p>'), p_attributes => 'target="_blank"');
  end if;
 
  return l_returnvalue;
 
end get_escaped_str_with_paragraph;


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


function get_absolute_url (p_url in varchar2,
                           p_base_url in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*
 
  Purpose:      get absolute URL
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.11.2013  Created
 
  */

  if instr(p_url, '://') > 0 then
    -- the URL already contains a protocol
    l_returnvalue := p_url;
  elsif substr(p_url, 1, 1) = '/' then
    l_returnvalue := p_base_url || p_url;
  else
    l_returnvalue := p_base_url || '/' || p_url;
  end if;

  return l_returnvalue;

end get_absolute_url;


function text_contains_markup (p_text in varchar2) return boolean
as
  l_returnvalue boolean;
begin
  
  /*

  Purpose:      returns true if text contains (HTML) markup
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.02.2015  Created
 
  */

  if p_text is null then
    l_returnvalue := false;
  else
    l_returnvalue := instr(p_text, '<') > 0;
  end if;

  return l_returnvalue;

end text_contains_markup;


function linkify_text (p_text in varchar2,
                       p_attributes in varchar2 := null) return varchar2
is
  l_begin_http                   number := 1;
  l_http_idx                     number := 1;
  l_http_length                  number := 0;
  l_returnvalue                  string_util_pkg.t_max_pl_varchar2;
begin
  
  /*
 
  Purpose:      change links in regular text into clickable links
 
  Remarks:      based on "wwv_flow_hot_http_links" in Apex 4.1, enhanced to handle both http and https
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     30.05.2013  Created
 
  */

  loop

     l_begin_http := regexp_instr(p_text || ' ', 'http://|https://', l_http_idx, 1, 0, 'i');

     exit when l_begin_http = 0;

     l_returnvalue := l_returnvalue || substr(p_text || ' ', l_http_idx, l_begin_http - l_http_idx);
     l_http_length := instr(replace(p_text,chr(10),' ') || ' ', ' ', l_begin_http) - l_begin_http;
     l_returnvalue := l_returnvalue || '<a ' || p_attributes || ' href="' || rtrim(substr(p_text || ' ', l_begin_http, l_http_length), '.') || '">' || substr(p_text || ' ', l_begin_http, l_http_length) || '</a>';
     l_http_idx := l_begin_http + l_http_length;

  end loop;

  l_returnvalue := l_returnvalue || substr(p_text || ' ', l_http_idx);

  return l_returnvalue;

end linkify_text;


end web_util_pkg;
/
 


