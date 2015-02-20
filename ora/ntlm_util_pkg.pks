create or replace package ntlm_util_pkg
as

  /*
 
  Purpose:      Package implements NTLM authentication protocol
 
  Remarks:      A PL/SQL port of the Python code at http://code.google.com/p/python-ntlm/
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     11.05.2011  Created
  MBR     11.05.2011  Miscellaneous contributions (create DES key, calculate LM hashed password, troubleshooting, bug fixes)
 
  */
  
  -- get negotiate message
  function get_negotiate_message (p_username in varchar2) return varchar2;

  -- parse challenge message from server                   
  procedure parse_challenge_message (p_message2 in varchar2,
                                     p_server_challenge out raw,
                                     p_negotiate_flags out raw);
                                     
  -- get authenticate message
  function get_authenticate_message (p_username in varchar2,
                                     p_password in varchar2,
                                     p_server_challenge in raw,
                                     p_negotiate_flags in raw) return varchar2;
                                     
  -- get LM hashed password v1
  function get_lm_hashed_password_v1 (p_password in raw) return raw;
  
  -- get response hash
  function get_response (p_password_hash in raw,
                         p_server_challenge in raw) return raw;


end ntlm_util_pkg;
/

