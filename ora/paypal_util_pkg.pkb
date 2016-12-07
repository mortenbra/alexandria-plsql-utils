create or replace package body paypal_util_pkg
as
 
  /*
 
  Purpose:      Package handles PayPal REST API
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */

  g_api_base_url_sandbox         string_util_pkg.t_max_db_varchar2 := 'https://api.sandbox.paypal.com';
  g_api_base_url_live            string_util_pkg.t_max_db_varchar2 := 'https://api.paypal.com';

  g_api_base_url                 string_util_pkg.t_max_db_varchar2 := g_api_base_url_live;

  g_wallet_path                  string_util_pkg.t_max_db_varchar2;
  g_wallet_password              string_util_pkg.t_max_db_varchar2;

 
procedure set_api_base_url (p_sandbox_url in varchar2,
                            p_live_url in varchar2)
as
begin

  /*
 
  Purpose:      set API base URL
 
  Remarks:      useful if you need to use a proxy for HTTPS requests from the database
                see http://blog.rhjmartens.nl/2015/07/making-https-webservice-requests-from.html
                see http://ora-00001.blogspot.com/2016/04/how-to-set-up-iis-as-ssl-proxy-for-utl-http-in-oracle-xe.html
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     06.03.2016  Created
 
  */

  -- set available URLs
  g_api_base_url_sandbox := p_sandbox_url;
  g_api_base_url_live := p_live_url;

  -- set the "live" URL as the default
  g_api_base_url := g_api_base_url_live;
  
end set_api_base_url;


function make_request (p_url in varchar2,
                       p_body in clob := null,
                       p_http_method in varchar2 := 'POST',
                       p_access_token in t_access_token := null,
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

  apex_web_service.g_request_headers.delete;

  if (p_access_token.access_token is not null) then
    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/json';
    apex_web_service.g_request_headers(2).name := 'Authorization';
    apex_web_service.g_request_headers(2).value := p_access_token.token_type || ' ' || p_access_token.access_token;
  else
    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';
    apex_web_service.g_request_headers(2).name := 'Accept';
    apex_web_service.g_request_headers(2).value := 'application/json';
    apex_web_service.g_request_headers(3).name := 'Accept-Language';
    apex_web_service.g_request_headers(3).value := 'en_US';
  end if;

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


function decode_json_value (p_json_value in varchar2) return varchar2
as
  l_returnvalue varchar2(32000);
begin

  /*
  
  Purpose:      decode JSON value
  
  Remarks:      
  
  Who      Date       Description
  ------  ----------  --------------------------------
  MBR     26.01.2010  Created
  
  */

  l_returnvalue := replace(p_json_value, '\''', '''');
  l_returnvalue := replace(l_returnvalue, '\"', '"');
  l_returnvalue := replace(l_returnvalue, '\b', chr(9));  -- backspace
  l_returnvalue := replace(l_returnvalue, '\t', chr(9));  -- tab
  l_returnvalue := replace(l_returnvalue, '\n', chr(10)); -- line feed
  l_returnvalue := replace(l_returnvalue, '\f', chr(12)); -- form feed
  l_returnvalue := replace(l_returnvalue, '\r', chr(13)); -- carriage return

  l_returnvalue := unistr(replace(l_returnvalue, '\u', '\')); -- unicode character

  return l_returnvalue;

end decode_json_value;


function encode_json_value (p_value in varchar2) return varchar2
as
  l_returnvalue varchar2(32000);
begin

  /*
  
  Purpose:      encode JSON value
  
  Remarks:      
  
  Who      Date        Description
  ------  ----------  --------------------------------
  MBR     19.04.2013  Created
  MBR     15.04.2015  Handle unicode chars properly, based on code from https://technology.amis.nl/wp-content/uploads/2015/03/json_agg.txt
  
  */

  l_returnvalue := asciistr(p_value);
  l_returnvalue := replace(l_returnvalue, '\', '\u');
  l_returnvalue := replace(l_returnvalue, '"', '\"');
  l_returnvalue := replace(l_returnvalue, '\u005C', '\\');
  l_returnvalue := replace(l_returnvalue, '/', '\/');
  l_returnvalue := replace(l_returnvalue, '''', '\''');
  l_returnvalue := replace(l_returnvalue, chr(8), '\b');  -- backspace
  l_returnvalue := replace(l_returnvalue, chr(9), '\t');  -- tab
  l_returnvalue := replace(l_returnvalue, chr(10), '\n'); -- line feed
  l_returnvalue := replace(l_returnvalue, chr(12), '\f'); -- form feed
  l_returnvalue := replace(l_returnvalue, chr(13), '\r'); -- carriage return

  return l_returnvalue;

end encode_json_value;


function encode_json_boolean (p_value in boolean) return varchar2
as
  l_returnvalue varchar2(32000);
begin

  /*
  
  Purpose:      encode JSON boolean value
  
  Remarks:      
  
  Who      Date       Description
  ------  ----------  --------------------------------
  MBR     17.11.2015  Created
  
  */

  if p_value then
    l_returnvalue := 'true';
  else
    l_returnvalue := 'false';
  end if;

  return l_returnvalue;

end encode_json_boolean;


function get_json_value (p_data in clob,
                         p_name in varchar2) return varchar2
as
  l_returnvalue varchar2(4000) := null;
  l_start_pos   pls_integer;
  l_end_pos     pls_integer;
begin

  /*
  
  Purpose:      get JSON value
  
  Remarks:      TODO: this is not a proper JSON parser, just a crude string parser, but will do for now. Refactor using APEX_JSON later...
  
  Who      Date       Description
  ------  ----------  --------------------------------
  MBR     26.01.2010  Created
  MBR     21.05.2010  Trim strings
  
  */

  -- assumes that values are always enclosed in double quotes (no null values)

  l_start_pos := instr(p_data, '"' || p_name || '":"');
  
  if l_start_pos > 0 then
    l_start_pos := l_start_pos + length ('"' || p_name || '":"');
    l_end_pos := instr(p_data, '",', l_start_pos);
    if l_end_pos = 0 then
      l_end_pos := instr(p_data, '"}', l_start_pos);
    end if;
    
    l_returnvalue := substr(p_data, l_start_pos, l_end_pos - l_start_pos);
    l_returnvalue := trim(replace(l_returnvalue, chr(160), ''));
     
  end if;
  
  if l_returnvalue is not null then
    l_returnvalue := substr(decode_json_value (l_returnvalue),1,4000);
  end if;

  return l_returnvalue;

end get_json_value;

 
procedure check_response_for_errors (p_response in clob) 
as
  l_error_name                   string_util_pkg.t_max_pl_varchar2;
  l_error_message                string_util_pkg.t_max_pl_varchar2;
  l_error_info_url               string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      check response for errors
 
  Remarks:      see https://developer.paypal.com/webapps/developer/docs/api/#errors
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */
 
  -- TODO: should pass the HTTP error code to this procedure as well (is it possible to get it via apex_web_service.g_headers???), for now just check response body

  debug_pkg.printf('response length = %1', length(p_response));
  debug_pkg.printf('first 32K characters of response = %1', substr(p_response,1,32000));

  -- note: this type of error response is not mentioned in the docs (linked above), but has been seen "in the wild"
  l_error_name := get_json_value (p_response, 'error');
  l_error_message := get_json_value (p_response, 'error_description');

  if l_error_name is not null then
    raise_application_error (-20000, 'The PayPal API returned error ' || l_error_name || ': ' || l_error_message, true);
  end if;

  -- check for errors as described by API documentation
  l_error_name := get_json_value (p_response, 'name');
  l_error_message := get_json_value (p_response, 'message');
  l_error_info_url := get_json_value (p_response, 'information_link');

  if l_error_name is not null then
    raise_application_error (-20000, 'The PayPal API returned error ' || l_error_name || ': ' || l_error_message || ', see ' || l_error_info_url, true);
  end if;
 
end check_response_for_errors;
  

procedure switch_to_sandbox 
as
begin
 
  /*
 
  Purpose:      switch to sandbox (test) environment
 
  Remarks:      the default environment is live (production), use this procedure to switch to the sandbox for testing
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */
 
  g_api_base_url := g_api_base_url_sandbox;
 
end switch_to_sandbox;
 
 
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
 
 
function get_access_token (p_client_id in varchar2,
                           p_secret in varchar2) return t_access_token
as
  l_request                      clob;
  l_response                     clob;
  l_returnvalue                  t_access_token;
begin
 
  /*
 
  Purpose:      get access token for other API requests
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */

  l_request := 'grant_type=client_credentials';

  l_response := make_request (p_url => g_api_base_url || '/v1/oauth2/token', p_body => l_request, p_username => p_client_id, p_password => p_secret);
 
  check_response_for_errors (l_response);

  l_returnvalue.access_token := get_json_value (l_response, 'access_token');
  l_returnvalue.token_type := get_json_value (l_response, 'token_type');
  -- TODO: retrieving this value fails because the current JSON parser only handles strings (ie values in double quotes), will be fixed by using APEX_JSON as the parser
  l_returnvalue.duration_seconds := to_number(get_json_value (l_response, 'expires_in'));
  l_returnvalue.created_date := sysdate;
  l_returnvalue.expires_date := l_returnvalue.created_date + (l_returnvalue.duration_seconds / (60*60));

  return l_returnvalue;
 
end get_access_token;
 

function get_payment_from_response (p_response in clob) return t_payment
as
  l_clob                         clob;
  l_end_pos                      pls_integer;
  l_returnvalue                  t_payment;
begin

  /*
 
  Purpose:      parse the response into a payment record
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */

  l_returnvalue.payment_id := get_json_value (p_response, 'id');
  l_returnvalue.intent := get_json_value (p_response, 'intent');
  l_returnvalue.state := get_json_value (p_response, 'state');

  -- TODO: this ain't pretty, use a real JSON parser (APEX_JSON) instead... ! (code will break if rel/href tags switch position)

  l_end_pos := instr(p_response, '"approval_url"');
  if l_end_pos > 0 then
    l_clob := p_response;
    l_clob := substr(l_clob, 1, l_end_pos);
    l_returnvalue.approval_url := substr(l_clob, instr(l_clob, '"href"', -1));
    l_returnvalue.approval_url := get_json_value (l_returnvalue.approval_url, 'href');
  end if;

  return l_returnvalue;
    
end get_payment_from_response;

 
function create_payment (p_access_token in t_access_token,
                         p_amount in number,
                         p_currency in varchar2,
                         p_description in varchar2,
                         p_return_url in varchar2,
                         p_cancel_url in varchar2,
                         p_payment_experience_id in varchar2 := null) return t_payment
as
  l_request                      clob;
  l_response                     clob;
  l_returnvalue                  t_payment;
begin
 
  /*
 
  Purpose:      create payment
 
  Remarks:      after calling this, redirect the user to the "approval_url" on the PayPal site,
                so that the user can approve the payment.
                The user must approve the payment before you can execute and complete the sale.

                When the user approves the payment, PayPal redirects the user to the "return_url"
                that was specified when the payment was created. A payer ID is appended to the return URL, as PayerID:
                http://<return_url>?token=EC-60U79048BN7719609(ampersand)PayerID=7E7MGXCWTTKK2
                The token value appended to the return URL is not needed when you execute the payment.

                To execute the payment after the user's approval, make a call to execute_payment and pass the payer_id received via the return_url
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
  MBR     17.11.2015  Added optional payment experience parameter
 
  */

  -- TODO: use a JSON builder to generate the request

  l_request := '{
  "intent":"sale",' || case when p_payment_experience_id is not null then '"experience_profile_id":"' || p_payment_experience_id || '",' end ||
  '"redirect_urls":{
    "return_url":"' || encode_json_value (p_return_url) || '",
    "cancel_url":"' || encode_json_value (p_cancel_url) || '"
  },
  "payer":{
    "payment_method":"paypal"
  },
  "transactions":[
    {
      "amount":{
        "total":"' || trim(to_char(p_amount, '999999D99', 'NLS_NUMERIC_CHARACTERS = ''. ''')) || '",
        "currency":"' || p_currency || '"
      },
      "description":"' || encode_json_value (p_description) || '"
    }
  ]
} ]
}';
 
  l_response := make_request (p_url => g_api_base_url || '/v1/payments/payment', p_body => l_request, p_access_token => p_access_token);
 
  check_response_for_errors (l_response);

  l_returnvalue := get_payment_from_response (l_response);

  return l_returnvalue;
 
end create_payment;
 
 
function execute_payment (p_access_token in t_access_token,
                          p_payment_id in varchar2,
                          p_payer_id in varchar2) return t_payment
as
  l_request                      clob;
  l_response                     clob;
  l_returnvalue                  t_payment;
begin
 
  /*
 
  Purpose:      execute payment
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */

  l_request := '{"payer_id":"' || p_payer_id || '"}';
 
  l_response := make_request (p_url => g_api_base_url || '/v1/payments/payment/' || p_payment_id || '/execute/', p_body => l_request, p_access_token => p_access_token);
 
  check_response_for_errors (l_response);

  l_returnvalue := get_payment_from_response (l_response);

  return l_returnvalue;
 
end execute_payment;
 

function get_payment (p_access_token in t_access_token,
                      p_payment_id in varchar2) return t_payment
as
  l_response                     clob;
  l_returnvalue                  t_payment;
begin
 
  /*
 
  Purpose:      get payment
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
 
  */

  l_response := make_request (p_url => g_api_base_url || '/v1/payments/payment/' || p_payment_id, p_http_method => 'GET', p_access_token => p_access_token);
 
  check_response_for_errors (l_response);

  l_returnvalue := get_payment_from_response (l_response);

  return l_returnvalue;
 
end get_payment;


function create_payment_experience (p_access_token in t_access_token,
                                    p_payment_experience in t_payment_experience) return varchar2
as
  l_request                      clob;
  l_response                     clob;
  l_returnvalue                  varchar2(255);
begin

  /*
 
  Purpose:      create payment experience
 
  Remarks:      see https://developer.paypal.com/docs/integration/direct/rest-experience-overview/
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.11.2015  Created
 
  */

  -- TODO: use a JSON builder to generate the request

  l_request := '{
  "name":"' || encode_json_value (p_payment_experience.payment_experience_name) || '",
  "presentation":{
    "brand_name":"' || encode_json_value (p_payment_experience.presentation.brand_name) || '",
    "logo_image":"' || encode_json_value (p_payment_experience.presentation.logo_image) || '",
    "locale_code":"' || encode_json_value (p_payment_experience.presentation.locale_code) || '"
  },
  "input_fields":{
    "allow_note":"' || encode_json_boolean (p_payment_experience.input_fields.allow_note) || '",
    "no_shipping":"' || p_payment_experience.input_fields.no_shipping || '",
    "address_override":"' || p_payment_experience.input_fields.address_override || '"
  },
  "flow_config":{
    "landing_page_type":"' || encode_json_value (p_payment_experience.flow_config.landing_page_type) || '"
  }
}';
 
  l_response := make_request (p_url => g_api_base_url || '/v1/payment-experience/web-profiles', p_body => l_request, p_access_token => p_access_token);
 
  -- TODO: according to the docs, the response should only contain "id",
  --       but the response actually contains the "name" of the payment experience, which throws a false error
  --check_response_for_errors (l_response);

  l_returnvalue := get_json_value (l_response, 'id');

  return l_returnvalue;

end create_payment_experience;


procedure delete_payment_experience (p_access_token in t_access_token,
                                     p_payment_experience_id in varchar2)
as
  l_response                     clob;
begin

  /*
 
  Purpose:      delete payment experience
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.11.2015  Created
 
  */

  l_response := make_request (p_url => g_api_base_url || '/v1/payment-experience/web-profiles/' || p_payment_experience_id, p_http_method => 'DELETE', p_access_token => p_access_token);
 
  check_response_for_errors (l_response);

end delete_payment_experience;


end paypal_util_pkg;
/
 
