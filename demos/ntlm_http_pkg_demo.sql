-- simple request

declare
  l_clob clob;
begin
  debug_pkg.debug_on;
  l_clob := ntlm_http_pkg.get_response_clob('http://servername/page', 'domain\username', 'password');
  debug_pkg.print(substr(l_clob, 1, 32000));
end;

-- begin/end request with one or more calls in-between

declare
  l_url           varchar2(2000) := 'http://servername/page';
  l_ntlm_auth_str varchar2(2000);
  l_xml           xmltype;
  l_soap_env      clob := 'your_soap_envelope_here';
  
begin
  debug_pkg.debug_on;

  -- perform the initial request to set up a persistent, authenticated connection
  l_ntlm_auth_str := ntlm_http_pkg.begin_request (l_url, 'domain\username', 'password');

  -- pass authorization header to next call(s)
  apex_web_service.g_request_headers(1).name := 'Authorization';
  apex_web_service.g_request_headers(1).value := l_ntlm_auth_str;

  -- perform the actual call
  -- NOTE: for this to work, you must be using a version of apex_web_service that does allows persistent connections (fixed in Apex 4.1 ???)
  --       see http://jastraub.blogspot.com/2008/06/flexible-web-service-api.html?showComment=1310198286769#c8685039598916415836
  l_xml := apex_web_service.make_request(l_url, 'soap_action_name_here', '1.1', l_soap_env);

  -- or use the latest version of flex_ws_api
  -- flex_ws_api.g_request_headers(1).name := 'Authorization';
  -- flex_ws_api.g_request_headers(1).value := l_ntlm_auth_str;
  -- l_xml := flex_ws_api.make_request(l_url, 'soap_action_name_here', '1.1', l_soap_env);

  -- this will close the persistent connection
  ntlm_http_pkg.end_request;

  debug_pkg.print('XML response from webservice', l_xml);
end;

