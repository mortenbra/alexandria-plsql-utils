create or replace package ntlm_http_pkg
as

  /*
 
  Purpose:      Package handles HTTP connections using NTLM authentication
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     03.06.2011  Created
  MBR     03.06.2011  Troubleshooting, bug fixes, handle persistent connection issues
  MBR     24.06.2011  Cleaned up code
  MBR     24.06.2011  Added begin/end_request
  MBR     25.07.2011  Added support for HTTPS and proxy server
 
  */
  
  -- get blob from url
  function get_response_blob (p_url in varchar2,
                              p_username in varchar2,
                              p_password in varchar2,
                              p_wallet_path in varchar2 := null,
                              p_wallet_password in varchar2 := null,
                              p_proxy_server in varchar2 := null) return blob;
							  
  -- get clob from url
  function get_response_clob (p_url in varchar2,
                              p_username in varchar2,
                              p_password in varchar2,
                              p_wallet_path in varchar2 := null,
                              p_wallet_password in varchar2 := null,
                              p_proxy_server in varchar2 := null) return clob;

  -- begin NTLM request
  function begin_request (p_url in varchar2,
                          p_username in varchar2,
                          p_password in varchar2,
                          p_wallet_path in varchar2 := null,
                          p_wallet_password in varchar2 := null,
                          p_proxy_server in varchar2 := null) return varchar2;

  -- end NTLM request
  procedure end_request;


end ntlm_http_pkg;
/
