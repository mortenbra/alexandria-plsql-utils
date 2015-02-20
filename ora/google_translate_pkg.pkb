create or replace package body google_translate_pkg
as

  /*

  Purpose:    PL/SQL wrapper package for Google Translate API

  Remarks:   see http://code.google.com/apis/ajaxlanguage/documentation/ 

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2009  Created
  
  */

  m_http_referrer                constant varchar2(255) := 'your-domain-name-or-website-here'; -- insert your domain/website here (required by Google's terms of use)
  m_api_key                      constant varchar2(255) := null; -- insert your Google API Key here (optional but recommended)

  m_service_url                  constant varchar2(255) := 'http://ajax.googleapis.com/ajax/services/language/';
  m_service_version              constant varchar2(10)  := '1.0';
  
  m_max_text_size                constant pls_integer   := 500; -- can be increased up towards 32k, the cache name size (below) must be increased accordingly 
  
  type t_translation_cache is table of varchar2(32000) index by varchar2(550);
  
  m_translation_cache            t_translation_cache;
  m_cache_id_separator           constant varchar2(1) := '|';


procedure add_to_cache (p_from_text in varchar2,
                        p_from_lang in varchar2,
                        p_to_text in varchar2,
                        p_to_lang in varchar2)
as
begin

  /*

  Purpose:    add translation to cache

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2009  Created
  
  */

  m_translation_cache (p_from_lang || m_cache_id_separator || p_to_lang || m_cache_id_separator || replace(substr(p_from_text,1,m_max_text_size), m_cache_id_separator, '')) := p_to_text;

end add_to_cache;
  

function get_from_cache (p_text in varchar2,
                         p_from_lang in varchar2,
                         p_to_lang in varchar2) return varchar2
as
  l_returnvalue varchar2(32000);
begin

  /*

  Purpose:    get translation from cache

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2009  Created
  
  */

  begin
    l_returnvalue := m_translation_cache (p_from_lang || m_cache_id_separator || p_to_lang || m_cache_id_separator || replace(substr(p_text,1,m_max_text_size), m_cache_id_separator, ''));
  exception
    when no_data_found then
      l_returnvalue := null;
  end;
  
  return l_returnvalue;

end get_from_cache;


function get_clob_from_http_post (p_url in varchar2,
                                  p_values in varchar2) return clob
as
  l_request     utl_http.req;
  l_response    utl_http.resp;
  l_buffer      varchar2(32767);
  l_returnvalue clob := ' ';
begin

  /*

  Purpose:    do a HTTP POST and get results back in a CLOB

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2009  Created
  
  */

  l_request := utl_http.begin_request (p_url, 'POST', utl_http.http_version_1_1);

  utl_http.set_header (l_request, 'Referer', m_http_referrer); -- note that the actual header name is misspelled in the HTTP protocol
  utl_http.set_header (l_request, 'Content-Type', 'application/x-www-form-urlencoded');
  utl_http.set_header (l_request, 'Content-Length', to_char(length(p_values)));
  utl_http.write_text (l_request, p_values);
  
  l_response := utl_http.get_response (l_request);
  
  if l_response.status_code = utl_http.http_ok then
  
    begin
      loop
        utl_http.read_text (l_response, l_buffer);
        dbms_lob.writeappend (l_returnvalue, length(l_buffer), l_buffer);
      end loop;
    exception
      when utl_http.end_of_body then
        null;
    end;
    
  end if;
  
  utl_http.end_response (l_response);

  return l_returnvalue;

end get_clob_from_http_post;


function translate_text (p_text in varchar2,
                         p_to_lang in varchar2,
                         p_from_lang in varchar2 := null,
                         p_use_cache in varchar2 := 'YES') return varchar2
as
  l_values      varchar2(2000);
  l_response    clob;
  l_start_pos   pls_integer;
  l_end_pos     pls_integer;
  l_returnvalue varchar2(32000) := null;
begin

  /*

  Purpose:    translate a piece of text

  Remarks:    if the "from" language is left blank, Google Translate will attempt to autodetect the language

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2009  Created
  MBR     25.12.2009  Added cache for translations
  
  */

  if trim(p_text) is not null then

    if p_use_cache = 'YES' then
      l_returnvalue := get_from_cache (p_text, p_from_lang, p_to_lang);
    end if;

    if l_returnvalue is null then
    
      l_values := 'v=' || m_service_version || '&q=' || utl_url.escape (substr(p_text,1,m_max_text_size), false, 'UTF8') || '&langpair=' || p_from_lang || '|' || p_to_lang;
      
      if m_api_key is not null then
        l_values := l_values || '&key=' || m_api_key;
      end if;
      
      l_response := get_clob_from_http_post (m_service_url || 'translate', l_values);
      
      if l_response is not null then

        l_start_pos := instr(l_response, '{"translatedText":"');
        l_start_pos := l_start_pos + 19;
        l_end_pos := instr(l_response, '"', l_start_pos);
        
        l_returnvalue := substr(l_response, l_start_pos, l_end_pos - l_start_pos);
        
        if (p_use_cache = 'YES') and (l_returnvalue is not null) then
          add_to_cache (p_text, p_from_lang, l_returnvalue, p_to_lang);
        end if;
        
      end if;

    end if;
    
  end if;
  
  return l_returnvalue;

end translate_text;


function detect_lang (p_text in varchar2) return varchar2
as
  l_url         varchar2(2000);
  l_response    clob;
  l_start_pos   pls_integer;
  l_end_pos     pls_integer;
  l_returnvalue varchar2(255);
begin

  /*

  Purpose:    detect language code for text

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2009  Created
  
  */

  if trim(p_text) is not null then
  
    l_url := m_service_url || 'detect?v=' || m_service_version || '&q=' || utl_url.escape (substr(p_text,1,m_max_text_size), false, 'UTF8');
        
    if m_api_key is not null then
      l_url := l_url || '&key=' || m_api_key;
    end if;
    
    l_response := httpuritype(l_url).getclob();

    l_start_pos := instr(l_response, '{"language":"');
    l_start_pos := l_start_pos + 13;
    l_end_pos := instr(l_response, '",', l_start_pos);
    
    l_returnvalue := substr(l_response, l_start_pos, l_end_pos - l_start_pos);
    
  end if;
  
  return l_returnvalue;

end detect_lang;


function get_translation_cache_count return number
as
  l_returnvalue number;
begin

  /*

  Purpose:    get number of texts in cache

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2009  Created
  
  */

  l_returnvalue := m_translation_cache.count;
  
  return l_returnvalue;

end get_translation_cache_count;


procedure clear_translation_cache
as
begin

  /*

  Purpose:    clear translation cache

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2009  Created
  
  */
  
  m_translation_cache.delete;

end clear_translation_cache;


end google_translate_pkg;
/

