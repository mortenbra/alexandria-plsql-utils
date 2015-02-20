declare
  l_env          t_soap_envelope;
  l_xml          xmltype;
begin

  -- the t_soap_envelope type can be used to generate a typical SOAP request envelope with just a few lines of code

  debug_pkg.debug_on;

  l_env := t_soap_envelope ('http://www.webserviceX.NET', 'globalweather.asmx', 'GetWeather', 'xmlns="http://www.webserviceX.NET"');

  l_env.add_param ('CityName', 'Stockholm');
  l_env.add_param ('CountryName', 'Sweden');

  l_xml := flex_ws_api.make_request (p_url => l_env.service_url, p_action => l_env.soap_action, p_envelope => l_env.envelope);

  -- if Apex 4+ is available:
  -- l_xml := apex_web_service.make_request (p_url => l_env.service_url, p_action => l_env.soap_action, p_envelope => l_env.envelope);

  debug_pkg.print (l_xml);

end;

