create or replace package body sms_util_pkg
as
 
  /*
 
  Purpose:      Package handles sending of SMS (Short Message Service) to mobile phones via an SMS gateway
 
  Remarks:      The package provides a generic interface and attempts to support "any" SMS gateway that provides an HTTP(S) (GET) interface
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.08.2014  Created
 
  */

  g_gateway_config               t_gateway_config;

  g_wallet_path                  string_util_pkg.t_max_db_varchar2;
  g_wallet_password              string_util_pkg.t_max_db_varchar2;

 
function make_request (p_url in varchar2,
                       p_body in clob := null,
                       p_http_method in varchar2 := 'POST',
                       p_username in varchar2 := null,
                       p_password in varchar2 := null) return clob
as
  l_returnvalue clob;
begin
 
  /*
 
  Purpose:      make HTTP request
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */

  debug_pkg.printf('%1 %2', p_http_method, p_url);

  l_returnvalue := apex_web_service.make_rest_request(
    p_url => p_url,
    p_http_method => p_http_method,
    p_body => p_body,
    p_username => p_username,
    p_password => p_password,
    p_wallet_path => g_wallet_path,
    p_wallet_pwd => g_wallet_password
  );

  return l_returnvalue;
 
end make_request;
 
 
procedure check_response_for_errors (p_response in clob) 
as
  l_xml                          xmltype;
  l_error_message                string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      check response for errors
 
  Remarks:      error handling is different for every SMS gateway (API provider)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.08.2014  Created
 
  */
 
  debug_pkg.printf('response length = %1', length(p_response));
  debug_pkg.printf('first 32K characters of response = %1', substr(p_response,1,32000));

  if g_gateway_config.response_format = g_format_xml then

    begin
      l_xml := xmltype (p_response);
      debug_pkg.printf('response converted to valid XML');
      if l_xml.existsnode (g_gateway_config.response_error_path) = 1 then
        debug_pkg.printf('error path node found, attempting to retrieve it');
        l_error_message := l_xml.extract(g_gateway_config.response_error_path, g_gateway_config.response_error_namespace).getstringval();
      else
        debug_pkg.printf('error path node not found, assuming no errors');
      end if;
    exception
      when others then
        l_error_message := sqlerrm;
    end;

  elsif g_gateway_config.response_format = g_format_custom then

    -- parse errors from response based on custom PL/SQL parsing function specified by the user
    -- this function should take a single clob parameter (the response from the SMS gateway) and return a varchar2 if an error is found in the response
    execute immediate 'begin sms_util_pkg.g_exec_result_string := ' || dbms_assert.sql_object_name(g_gateway_config.response_error_parser) || ' (:b1); end;' using p_response;
    l_error_message := g_exec_result_string;

  else
    -- TODO: implement JSON parsing using APEX_JSON (if Apex 5+ is installed)
    raise_application_error (-20000, 'Response format ' || g_gateway_config.response_format || ' not supported or not implemented!');
  end if;

  if l_error_message is not null then
    raise_application_error (-20000, 'The SMS gateway returned an error: ' || l_error_message, true);
  end if;
 
end check_response_for_errors;


procedure set_wallet (p_wallet_path in varchar2,
                      p_wallet_password in varchar2) 
as
begin
 
  /*
 
  Purpose:      set SSL wallet properties
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */
 
  g_wallet_path := p_wallet_path;
  g_wallet_password := p_wallet_password;
 
end set_wallet;


procedure set_gateway_config (p_gateway_config in t_gateway_config) 
as
begin
 
  /*
 
  Purpose:      set gateway configuration
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */
 
  g_gateway_config := p_gateway_config;
 
end set_gateway_config;


procedure send_sms (p_message in varchar2,
                    p_to in varchar2,
                    p_from in varchar2,
                    p_attr1 in varchar2 := null,
                    p_attr2 in varchar2 := null,
                    p_attr3 in varchar2 := null,
                    p_username in varchar2 := null,
                    p_password in varchar2 := null)
as
  l_url                          string_util_pkg.t_max_pl_varchar2;
  l_response                     clob;

  function url_escape (p_text in varchar2) return varchar2
  as
  begin
    return utl_url.escape (p_text, escape_reserved_chars => false, url_charset => 'UTF8');
  end url_escape;

begin
 
  /*
 
  Purpose:      send SMS message
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.08.2014  Created
 
  */

  -- TODO: assert that configuration exists

  l_url := string_util_pkg.multi_replace (
    g_gateway_config.send_sms_url,
    t_str_array('#username#', '#password#', '#message#', '#to#', '#from#', '#attr1#', '#attr2#', '#attr3#'),
    t_str_array(coalesce(p_username, g_gateway_config.username), coalesce(p_password, g_gateway_config.password), url_escape(p_message), url_escape(p_to), url_escape(p_from), p_attr1, p_attr2, p_attr3)
  );

  l_response := make_request (p_url => l_url, p_http_method => 'GET');
 
  check_response_for_errors (l_response);
 
end send_sms;


end sms_util_pkg;
/
 
