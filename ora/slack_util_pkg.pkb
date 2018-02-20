create or replace package body slack_util_pkg
as
 
  /*
 
  Purpose:      Package handles Slack API
 
  Remarks:      see https://api.slack.com/

  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.02.2018  Created
 
  */

  g_api_base_url                 string_util_pkg.t_max_db_varchar2 := 'https://slack.com/api';

  g_webhook_host                 string_util_pkg.t_max_db_varchar2 := 'https://hooks.slack.com';
  g_webhook_path                 string_util_pkg.t_max_db_varchar2;

  g_wallet_path                  string_util_pkg.t_max_db_varchar2;
  g_wallet_password              string_util_pkg.t_max_db_varchar2;


procedure assert (p_condition in boolean,
                  p_error_message in varchar2)
as
begin

  /*
 
  Purpose:      assert condition is true, otherwise raise an error
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     20.02.2018  Created
 
  */

  if (p_condition is null) or (not p_condition) then
    raise_application_error (-20000, p_error_message);
  end if;

end assert;


function make_request (p_url in varchar2,
                       p_body in clob := null,
                       p_http_method in varchar2 := 'POST') return clob
as
  l_http_status_code             pls_integer;
  l_returnvalue                  clob;
begin
 
  /*
 
  Purpose:      make HTTP request
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.02.2018  Created
 
  */

  apex_web_service.g_request_headers.delete;

  apex_web_service.g_request_headers(1).name := 'Content-Type';
  apex_web_service.g_request_headers(1).value := 'application/json';

  l_returnvalue := apex_web_service.make_rest_request(
    p_url => p_url,
    p_http_method => p_http_method,
    p_body => p_body,
    p_wallet_path => g_wallet_path,
    p_wallet_pwd => g_wallet_password
  );

  l_http_status_code := apex_web_service.g_status_code;

  -- for possible error codes, see https://api.slack.com/changelog/2016-05-17-changes-to-errors-for-incoming-webhooks
  assert (l_http_status_code = 200, 'Request failed with HTTP error code ' || l_http_status_code || '. First 1K of response body: ' || substr(l_returnvalue, 1, 1000) );

  return l_returnvalue;
 
end make_request;

 
procedure set_api_base_url (p_url in varchar2)
as
begin

  /*
 
  Purpose:      set API base URL
 
  Remarks:      useful if you need to use a proxy for HTTPS requests from the database
                see http://blog.rhjmartens.nl/2015/07/making-https-webservice-requests-from.html
                see http://ora-00001.blogspot.com/2016/04/how-to-set-up-iis-as-ssl-proxy-for-utl-http-in-oracle-xe.html
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.02.2018  Created
 
  */

  g_api_base_url := p_url;
  
end set_api_base_url;

 
procedure set_wallet (p_wallet_path in varchar2,
                      p_wallet_password in varchar2) 
as
begin
 
  /*
 
  Purpose:      set SSL wallet properties
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.02.2018  Created
 
  */
 
  g_wallet_path := p_wallet_path;
  g_wallet_password := p_wallet_password;
 
end set_wallet;


procedure set_webhook_host (p_host in varchar2)
as
begin

  /*
 
  Purpose:      set webhook host
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.02.2018  Created
 
  */
  
  g_webhook_host := p_host;

end set_webhook_host;


procedure set_webhook_path (p_path in varchar2)
as
begin

  /*
 
  Purpose:      set webhook path
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.02.2018  Created
 
  */
  
  g_webhook_path := p_path;

end set_webhook_path;


procedure send_message (p_text in varchar2)
as
  l_response clob;
begin

  /*
 
  Purpose:      send message
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.02.2018  Created
 
  */

  assert (g_webhook_host is not null, 'Webhook host not defined!');
  assert (g_webhook_path is not null, 'Webhook path not defined!');

  l_response := make_request (
    p_url => g_webhook_host || g_webhook_path,
    p_body => '{ "text": ' || apex_json.stringify (p_text) || ' }'
  );


end send_message;
 

end slack_util_pkg;
/

