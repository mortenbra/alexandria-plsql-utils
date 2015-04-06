create or replace package body ntlm_http_pkg
as
  c_blob                         constant number(1) := 0;
  c_clob                         constant number(1) := 1;

  type t_response_body is record (
		l_blob                   blob,
		l_clob                   clob,
		l_blob_or_clob           number(1) default 1
  );

  /*
 
  Purpose:      Package handles HTTP connections using NTLM authentication
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     03.06.2011  Created
  MBR     03.06.2011  Troubleshooting, bug fixes, handle persistent connection issues
  MBR     24.06.2011  Cleaned up code
  MBR     24.06.2011  Added begin/end_request
 
  */
  

function headers_contain_value (p_resp in out utl_http.resp,
                                p_name in varchar2,
                                p_value in varchar2) return boolean
as
  l_name                         varchar2(2000);
  l_value                        varchar2(2000);
  l_returnvalue                  boolean := false;
begin
  
  /*
   
  Purpose:      return true if response headers contain a specific name/value pair  
   
  Remarks:      
   
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.07.2011  Created
   
  */

  for i in 1 .. utl_http.get_header_count (p_resp) loop
    utl_http.get_header (p_resp, i, l_name, l_value);
    if (l_name = p_name) and (l_value = p_value) then
      l_returnvalue := true;
      exit;
    end if;
  end loop;
  
  return l_returnvalue;
  
end headers_contain_value;


procedure get_response_body (p_resp in out utl_http.resp, p_response_body in out nocopy t_response_body)
as
  l_bdata       raw(32767);
  l_cdata       string_util_pkg.t_max_pl_varchar2;
begin
  /*
 
  Purpose:      get the response body as a blob
   
  Remarks:      
   
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.06.2011  Created
  EAO     22.03.2015  Works with BLOBs
   
  */
    
  if p_response_body.l_blob_or_clob = c_blob then
    begin
      loop
        utl_http.read_raw(r => p_resp, data => l_bdata);
        dbms_lob.append( p_response_body.l_blob, to_blob( l_bdata ));
      end loop;
    exception
      when utl_http.end_of_body then
        null;
    end;
  else
    begin
      loop
        utl_http.read_text(r => p_resp, data => l_cdata);
        p_response_body.l_clob := p_response_body.l_clob || l_cdata;
      end loop;
    exception
      when utl_http.end_of_body then
        null;
    end;
  end if;
end get_response_body;


procedure get_response (p_url in varchar2,
                        p_username in varchar2,
                        p_password in varchar2,
                        p_wallet_path in varchar2 := null,
                        p_wallet_password in varchar2 := null,
                        p_proxy_server in varchar2 := null,
                        p_response_body in out nocopy t_response_body)
as

  l_req                          utl_http.req;
  l_resp                         utl_http.resp;
  l_returnvalue                  blob;
  
  l_authenticate_with_ntlm       boolean;
  
  l_name                         varchar2(500);
  l_value                        varchar2(500);
  
  l_ntlm_message                 varchar2(500);
  
  l_negotiate_message            varchar2(500);
  
  l_server_challenge             raw(4000);
  l_negotiate_flags              raw(4000);

  l_authenticate_message         varchar2(500);
  
  procedure debug_response (p_resp in out utl_http.resp)
  as
    l_name  varchar2(255);
    l_value varchar2(2000);
    l_body  clob;
  begin

    debug_pkg.printf('Response Status Code: %1', p_resp.status_code);

    for i in 1 .. utl_http.get_header_count (p_resp) loop
      utl_http.get_header (p_resp, i, l_name, l_value);
      debug_pkg.printf('#%1 %2 : %3', i, l_name, l_value);
    end loop;
      
    get_response_body (p_resp, p_response_body);

    debug_pkg.printf('Body length = %1', dbms_lob.getlength (l_returnvalue));
    debug_pkg.printf('Persistent connection count: %1', utl_http.get_persistent_conn_count);

  end debug_response;
  

begin
  /*
 
  Purpose:      Get response clob from URL
 
  Remarks:      see http://davenport.sourceforge.net/ntlm.html#ntlmHttpAuthentication
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     11.05.2011  Created
  MBR     03.06.2011  Lots of changes
 
  */
  
  utl_http.set_detailed_excp_support (enable => true);
  utl_http.set_response_error_check (false);

  utl_http.set_persistent_conn_support (true, 10);

  debug_pkg.printf('Persistent connection count: %1', utl_http.get_persistent_conn_count);

  -- support for HTTPS
  if instr(lower(p_url),'https') = 1 then
    utl_http.set_wallet (p_wallet_path, p_wallet_password);
  end if;
  
  -- support for proxy server
  if p_proxy_server is not null then
    utl_http.set_proxy (p_proxy_server);
  end if;

  ------------
  -- Request 1
  ------------
  
  debug_pkg.printf(' ');
  debug_pkg.printf(p_url);
      
  l_req := utl_http.begin_request(p_url);

  l_resp := utl_http.get_response (l_req);

  debug_response (l_resp);
      
  if l_resp.status_code = utl_http.HTTP_UNAUTHORIZED then
    
    l_authenticate_with_ntlm := headers_contain_value (l_resp, 'WWW-Authenticate', 'NTLM');
        
    utl_http.end_response (l_resp);
        
    if l_authenticate_with_ntlm then
        
      l_negotiate_message := 'NTLM ' || ntlm_util_pkg.get_negotiate_message(p_username);
      -- need to send negotiation message
          
      debug_pkg.printf('Negotiate message: %1', l_negotiate_message);
          
      ------------
      -- Request 2
      ------------

      debug_pkg.printf(' ');
      debug_pkg.printf(p_url);
      l_req :=  utl_http.begin_request(p_url);
      utl_http.set_header (l_req, 'Authorization', l_negotiate_message);

      l_resp := utl_http.get_response(l_req);

      debug_response (l_resp);
          
      if l_resp.status_code = utl_http.HTTP_UNAUTHORIZED then

        -- received server challenge
        utl_http.get_header_by_name(l_resp, 'WWW-Authenticate', l_value, 1);

        utl_http.end_response(l_resp);

        if substr(l_value, 1, 4) = 'NTLM' then

          -- get value
          l_value := substr(l_value, 6);

          ntlm_util_pkg.parse_challenge_message (l_value, l_server_challenge, l_negotiate_flags);
              
          l_authenticate_message := 'NTLM ' || ntlm_util_pkg.get_authenticate_message(p_username, p_password, l_server_challenge, l_negotiate_flags);
          debug_pkg.printf('Authenticate message: "%1"', l_authenticate_message);
              
          ------------
          -- Request 3
          ------------

          -- sending NTLM message 3
          debug_pkg.printf(' ');
          debug_pkg.printf(p_url);
          l_req :=  utl_http.begin_request(p_url);

          utl_http.set_header (l_req, 'Connection', 'close');
          utl_http.set_header (l_req, 'Authorization', l_authenticate_message);

          l_resp := utl_http.get_response (l_req);

          debug_response (l_resp);

          -- this is already done inside debug_response
          --l_returnvalue := get_response_body (l_resp);
              
          utl_http.end_response(l_resp);

        end if;

      end if;
         
    else
      debug_pkg.printf('Server is not configured with NTLM security (missing "WWW-Authenticate: NTLM" header).');
    end if;
  
  end if; 
        
  
  utl_http.close_persistent_conns;
  debug_pkg.printf('Persistent connection count (should be zero): %1', utl_http.get_persistent_conn_count);

end get_response;


function get_response_blob (p_url in varchar2,
                            p_username in varchar2,
                            p_password in varchar2,
                            p_wallet_path in varchar2 := null,
                            p_wallet_password in varchar2 := null,
                            p_proxy_server in varchar2 := null) return blob
as
  l_response_body       t_response_body;
begin

  /*
 
  Purpose:      Get response clob from URL
 
  Remarks:      see http://davenport.sourceforge.net/ntlm.html#ntlmHttpAuthentication
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     11.05.2011  Created
  MBR     03.06.2011  Lots of changes
  EAO     22.03.2015  Most functionality moved to get_response
 
  */
  
  dbms_lob.createtemporary( l_response_body.l_blob, true);
  l_response_body.l_blob_or_clob := c_blob;
  get_response(
    p_url             => get_response_blob.p_url,
    p_username        => get_response_blob.p_username,
    p_password        => get_response_blob.p_password,
    p_wallet_path     => get_response_blob.p_wallet_path,
    p_wallet_password => get_response_blob.p_wallet_password,
    p_proxy_server    => get_response_blob.p_proxy_server,
    p_response_body   => l_response_body);

  return l_response_body.l_blob;

end get_response_blob;


function get_response_clob (p_url in varchar2,
                            p_username in varchar2,
                            p_password in varchar2,
                            p_wallet_path in varchar2 := null,
                            p_wallet_password in varchar2 := null,
                            p_proxy_server in varchar2 := null) return clob
as
  l_response_body       t_response_body;
begin
  dbms_lob.createtemporary( l_response_body.l_clob, true);
  l_response_body.l_blob_or_clob := c_clob;
  
  get_response(
    p_url             => get_response_clob.p_url,
    p_username        => get_response_clob.p_username,
    p_password        => get_response_clob.p_password,
    p_wallet_path     => get_response_clob.p_wallet_path,
    p_wallet_password => get_response_clob.p_wallet_password,
    p_proxy_server    => get_response_clob.p_proxy_server,
    p_response_body   => l_response_body);

  return l_response_body.l_clob;
  
end get_response_clob;


function begin_request (p_url in varchar2,
                        p_username in varchar2,
                        p_password in varchar2,
                        p_wallet_path in varchar2 := null,
                        p_wallet_password in varchar2 := null,
                        p_proxy_server in varchar2 := null) return varchar2
as

  l_method                       varchar2(255) := 'GET';

  l_req                          utl_http.req;
  l_resp                         utl_http.resp;
  l_response_body                clob;
  
  l_returnvalue                  varchar2(2000);
  
  l_name                         varchar2(500);
  l_value                        varchar2(500);
  
  l_ntlm_message                 varchar2(500);
  l_negotiate_message            varchar2(500);
  l_server_challenge             raw(4000);
  l_negotiate_flags              raw(4000);
  l_authenticate_message         varchar2(500);


  function get_response_body (p_resp in out utl_http.resp) return clob
  as
    l_data        string_util_pkg.t_max_pl_varchar2;
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get the response body as a clob
   
    Remarks:      
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     24.06.2011  Created
   
    */
    
    begin
      loop
        utl_http.read_text(r => p_resp, data => l_data);
        l_returnvalue := l_returnvalue || l_data;
      end loop;
    exception
      when utl_http.end_of_body then
        null;
    end;
      
    return l_returnvalue;

  end get_response_body;


  procedure debug_response (p_resp in out utl_http.resp)
  as
    l_name  varchar2(255);
    l_value varchar2(2000);
  begin

    /*
   
    Purpose:      print debug info about the response
   
    Remarks:      
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     24.06.2011  Created
   
    */

    debug_pkg.printf('Response Status Code: %1', p_resp.status_code);

    for i in 1 .. utl_http.get_header_count (p_resp) loop
      utl_http.get_header (p_resp, i, l_name, l_value);
      debug_pkg.printf('#%1 %2 : %3', i, l_name, l_value);
    end loop;
      
    l_response_body := get_response_body (p_resp);

    debug_pkg.printf('Body length = %1', dbms_lob.getlength (l_response_body));
    debug_pkg.printf('Persistent connection count: %1', utl_http.get_persistent_conn_count);

  end debug_response;


begin

  /*
 
  Purpose:      begin NTLM request
 
  Remarks:      it is assumed that the request will be against an NTLM-protected URL, so the initial request (where the server responds with WWW-Authenticate: NTLM) is skipped 
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.06.2011  Created
 
  */

  utl_http.set_detailed_excp_support (enable => true);
  utl_http.set_response_error_check (enable => false);

  utl_http.set_persistent_conn_support (true, 10);

  -- support for HTTPS
  if instr(lower(p_url),'https') = 1 then
    utl_http.set_wallet (p_wallet_path, p_wallet_password);
  end if;
  
  -- support for proxy server
  if p_proxy_server is not null then
    utl_http.set_proxy (p_proxy_server);
  end if;


  l_negotiate_message := 'NTLM ' || ntlm_util_pkg.get_negotiate_message (p_username);

  debug_pkg.printf('Negotiate Message: %1', l_negotiate_message);
          
  ------------
  -- Request 1
  ------------

  debug_pkg.printf(' ');
  debug_pkg.printf(l_method || ' ' || p_url);

  l_req :=  utl_http.begin_request (p_url, l_method);
  utl_http.set_header (l_req, 'Authorization', l_negotiate_message);

  l_resp := utl_http.get_response(l_req);

  debug_response (l_resp);
          
  if l_resp.status_code = utl_http.http_unauthorized then

    -- received server challenge
    utl_http.get_header_by_name (l_resp, 'WWW-Authenticate', l_value, 1);
    utl_http.end_response (l_resp);

    if substr(l_value, 1, 4) = 'NTLM' then

      l_value := substr(l_value, 6);

      ntlm_util_pkg.parse_challenge_message (l_value, l_server_challenge, l_negotiate_flags);
      l_authenticate_message := 'NTLM ' || ntlm_util_pkg.get_authenticate_message (p_username, p_password, l_server_challenge, l_negotiate_flags);
      
      debug_pkg.printf('Authenticate Message: "%1"', l_authenticate_message);
      
      -- this is what needs to be passed as the Authorization header in the next call (and TCP connection must be kept persistent)
      l_returnvalue := l_authenticate_message;

    end if;

  else
  
    utl_http.end_response (l_resp);
    l_returnvalue := null;

  end if;

  return l_returnvalue;

end begin_request;


procedure end_request
as
begin


  /*
 
  Purpose:      end NTLM request
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.06.2011  Created
 
  */

  debug_pkg.printf('Persistent connection count: %1', utl_http.get_persistent_conn_count);
  utl_http.close_persistent_conns;
  debug_pkg.printf('Persistent connection count (should be zero): %1', utl_http.get_persistent_conn_count);

end end_request;



end ntlm_http_pkg;
/
