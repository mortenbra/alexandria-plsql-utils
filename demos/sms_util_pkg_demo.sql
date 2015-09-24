
-- send sms (text message) via gateway
-- the configuration must be adapted to a specific gateway api
-- for example, see http://www.smsglobal.com/http-api/

-- sign up with a gateway provider to obtain a username and password

/*

-- the following tags can be used in the url template

#username#
#password#
#message#
#to#
#from#
#attr1#
#attr2#
#attr3#

*/

declare
  l_config sms_util_pkg.t_gateway_config;
begin
  -- configure gateway
  -- remember you may have to open this hostname in the database Network ACL
  l_config.send_sms_url := 'http://www.smsglobal.com/http-api.php?action=sendsms&user=#username#r&password=#password#&from=#from#&to=#to#&
text=#message#';
  l_config.username := 'testuser';
  l_config.password := 'secret';
  l_config.response_format := sms_util_pkg.g_format_custom;
  l_config.response_error_parser := 'my_package.my_error_parser'; -- this is a function that accepts a clob and returns a varchar2
  sms_util_pkg.set_gateway_config (l_config);
  -- if using HTTPS you need to set up an Oracle wallet with the certificate
  -- sms_util_pkg.set_wallet (p_wallet_path => '/path/to/wallet/', p_wallet_password => 'somesecret');
  -- send the message
  sms_util_pkg.sends_sms (p_message => 'Hello SMS World', p_to => 123456789, p_from => 'BobSacamano');
end;
/