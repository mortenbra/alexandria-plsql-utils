create or replace package body ntlm_util_pkg
as

  /*
 
  Purpose:      Package implements NTLM authentication protocol
 
  Remarks:      A PL/SQL port of the Python code at http://code.google.com/p/python-ntlm/
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     11.05.2011  Created
  MBR     11.05.2011  Miscellaneous contributions
 
  */
  
  m_NTLM_NegotiateUnicode        constant raw(4) := utl_raw.cast_from_binary_integer(1); --'00000001';
  m_NTLM_NegotiateOEM            constant raw(4) := utl_raw.cast_from_binary_integer(2); --'00000002';
  m_NTLM_RequestTarget           constant raw(4) := utl_raw.cast_from_binary_integer(4); --'00000004';
  m_NTLM_Unknown9                constant raw(4) := utl_raw.cast_from_binary_integer(8); -- '00000008';
  m_NTLM_NegotiateSign           constant raw(4) := utl_raw.cast_from_binary_integer(16); --'00000010';
  m_NTLM_NegotiateSeal           constant raw(4) := utl_raw.cast_from_binary_integer(32); --'00000020';
  m_NTLM_NegotiateDatagram       constant raw(4) := utl_raw.cast_from_binary_integer(64); --'00000040';
  m_NTLM_NegotiateLanManagerKey  constant raw(4) := utl_raw.cast_from_binary_integer(128); --'00000080';
  m_NTLM_Unknown8                constant raw(4) := utl_raw.cast_from_binary_integer(256); --'00000100';
  m_NTLM_NegotiateNTLM           constant raw(4) := utl_raw.cast_from_binary_integer(512); --'00000200';
  m_NTLM_NegotiateNTOnly         constant raw(4) := utl_raw.cast_from_binary_integer(1024); --'00000400';
  m_NTLM_Anonymous               constant raw(4) := utl_raw.cast_from_binary_integer(2048); --'00000800';
  m_NTLM_NegotiateOemDomainSuppl constant raw(4) := utl_raw.cast_from_binary_integer(4096); --'00001000';
  m_NTLM_NegotiateOemWorkstation constant raw(4) := utl_raw.cast_from_binary_integer(8192); --'00002000';
  m_NTLM_Unknown6                constant raw(4) := utl_raw.cast_from_binary_integer(16384); --'00004000';
  m_NTLM_NegotiateAlwaysSign     constant raw(4) := utl_raw.cast_from_binary_integer(32768); --'00008000';
  m_NTLM_TargetTypeDomain        constant raw(4) := utl_raw.cast_from_binary_integer(65536); --'00010000';
  m_NTLM_TargetTypeServer        constant raw(4) := utl_raw.cast_from_binary_integer(131072); --'00020000';
  m_NTLM_TargetTypeShare         constant raw(4) := utl_raw.cast_from_binary_integer(262144); --'00040000';
  m_NTLM_NegotiateExtendedSec    constant raw(4) := utl_raw.cast_from_binary_integer(524288); --'00080000';
  m_NTLM_NegotiateIdentify       constant raw(4) := utl_raw.cast_from_binary_integer(1048576); --'00100000';
  m_NTLM_Unknown5                constant raw(4) := utl_raw.cast_from_binary_integer(2097152); --'00200000';
  m_NTLM_RequestNonNTSessionKey  constant raw(4) := utl_raw.cast_from_binary_integer(4194304); --'00400000';
  m_NTLM_NegotiateTargetInfo     constant raw(4) := utl_raw.cast_from_binary_integer(8388608); --'00800000';
  m_NTLM_Unknown4                constant raw(4) := utl_raw.cast_from_binary_integer(16777216); --'01000000';
  m_NTLM_NegotiateVersion        constant raw(4) := utl_raw.cast_from_binary_integer(33554432); --'02000000';
  m_NTLM_Unknown3                constant raw(4) := utl_raw.cast_from_binary_integer(67108864); --'04000000';
  m_NTLM_Unknown2                constant raw(4) := utl_raw.cast_from_binary_integer(134217728); --'08000000';
  m_NTLM_Unknown1                constant raw(4) := utl_raw.cast_from_binary_integer(268435456); --'10000000';
  m_NTLM_Negotiate128            constant raw(4) := utl_raw.cast_from_binary_integer(536870912); --'20000000';
  m_NTLM_NegotiateKeyExchange    constant raw(4) := utl_raw.cast_from_binary_integer(1073741824); --'40000000';
  m_NTLM_Negotiate56             constant raw(4) := utl_raw.cast_from_binary_integer(128, utl_raw.little_endian); -- '80000000'; -- using little endian instead of big beacuse utl_raw.cast_from_binary_integer(2147483648) results in overflow

  
function bit_or_multi (p_raw1 in raw,
                       p_raw2 in raw,
                       p_raw3 in raw := null,
                       p_raw4 in raw := null,
                       p_raw5 in raw := null,
                       p_raw6 in raw := null,
                       p_raw7 in raw := null,
                       p_raw8 in raw := null,
                       p_raw9 in raw := null,
                       p_raw10 in raw := null,
                       p_raw11 in raw := null,
                       p_raw12 in raw := null) return raw
as
  l_returnvalue raw(5000);
begin

 /*
 
  Purpose:      Perform bitwise OR operations on multiple RAWs
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.05.2011  Created
 
  */
  
  l_returnvalue := utl_raw.bit_or(p_raw1, p_raw2);
  
  if p_raw3 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw3);
  end if;

  if p_raw4 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw4);
  end if;
  
  if p_raw5 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw5);
  end if;

  if p_raw6 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw6);
  end if;

  if p_raw7 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw7);
  end if;

  if p_raw8 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw8);
  end if;

  if p_raw9 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw9);
  end if;

  if p_raw10 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw10);
  end if;

  if p_raw11 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw11);
  end if;

  if p_raw12 is not null then
    l_returnvalue := utl_raw.bit_or(l_returnvalue, p_raw12);
  end if;

  
  return l_returnvalue;
  
end bit_or_multi;


function int_to_raw_little_endian (p_number in number,
                                   p_length in number) return raw
as
  l_returnvalue raw(5000);
begin

  /*
 
  Purpose:      Returning little endian value of integer of specified length
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.05.2011  Created
 
  */
  
  l_returnvalue := utl_raw.substr(utl_raw.cast_from_binary_integer(p_number, utl_raw.little_endian), 1, p_length);
  
  return l_returnvalue;

end int_to_raw_little_endian;


function get_workstation_name return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin

  /*
 
  Purpose:      Get workstation name for executing user
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.05.2011  Created
 
  */
  
  --l_returnvalue := sys_context('USERENV', 'TERMINAL');
  l_returnvalue := upper(sys_context('USERENV', 'server_host'));
  
  return l_returnvalue;

end get_workstation_name;


procedure parse_username (p_username in varchar2,
                          p_domain out varchar2,
                          p_user out varchar2)
as
begin

  /*
 
  Purpose:      Parse username as domain\user
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.05.2011  Created
 
  */

  if instr(p_username, '\') > 0 then
    p_domain := upper (substr(p_username, 1, instr(p_username, '\')-1));
    p_user := substr(p_username, instr(p_username, '\') + 1, length(p_username) - instr(p_username, '\') + 1);
  else
    p_domain := null;
    p_user := p_username;
  end if;

end parse_username;
  
  
function get_negotiate_message (p_username in varchar2) return varchar2
as
  
  l_body_length                   number;
  l_payload_start                 number;
  
  l_domain_str                    varchar2(500);
  l_user_str                      varchar2(500);

  --l_protocol                      raw(8);
  l_protocol                      raw(16);
  l_workstation                   raw(16);
  l_domain                        raw(16);

  l_type                          raw(4);
  l_flags                         raw(4);
  
  l_workstation_length            raw(2);
  l_workstation_max_length        raw(2);
  l_workstation_buffer_offset     raw(4);
  
  l_domain_length                 raw(2);
  l_domain_max_length             raw(2);
  l_domain_buffer_offset          raw(4);
  
  l_product_major_version         raw(1);
  l_product_minor_version         raw(1);
  l_product_build                 raw(2);
  
  l_version_reserved1             raw(1);
  l_version_reserved2             raw(1);
  l_version_reserved3             raw(1);

  l_ntlm_revision_current         raw(1);
  
  l_return                        raw(100);
  
  l_returnvalue                   string_util_pkg.t_max_pl_varchar2;
  
begin

  /*
 
  Purpose:      Get negotiate message
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.05.2011  Created
 
  */
  
  l_body_length := 40;
  l_payload_start := l_body_length;
  
  --l_protocol := utl_raw.cast_to_raw('NTLMSSP' || chr(256));
  l_protocol := utl_raw.cast_to_raw('NTLMSSP' || chr(0));
  
  l_type := int_to_raw_little_endian(1, 4); --- Type 1
  
  l_flags := bit_or_multi (m_NTLM_NegotiateUnicode,
                           m_NTLM_NegotiateOEM,
                           m_NTLM_RequestTarget,
                           m_NTLM_NegotiateNTLM,
                           m_NTLM_NegotiateOemDomainSuppl,
                           m_NTLM_NegotiateOemWorkstation,
                           m_NTLM_NegotiateAlwaysSign,
                           m_NTLM_NegotiateExtendedSec,
                           m_NTLM_NegotiateVersion,
                           m_NTLM_Negotiate128,
                           m_NTLM_Negotiate56);
  
  -- need to convert flags to little endian
  l_flags := int_to_raw_little_endian (utl_raw.cast_to_binary_integer(l_flags), 4);
  
  l_workstation := utl_raw.cast_to_raw(get_workstation_name);
  parse_username (p_username, l_domain_str, l_user_str);
  l_domain := utl_raw.cast_to_raw(l_domain_str);
  
  l_workstation_length := int_to_raw_little_endian (utl_raw.length(l_workstation), 2);
  l_workstation_max_length := int_to_raw_little_endian (utl_raw.length(l_workstation), 2);
  l_workstation_buffer_offset := int_to_raw_little_endian (l_payload_start, 4);
  
  l_payload_start := l_payload_start + utl_raw.length (l_workstation);
  
  l_domain_length := int_to_raw_little_endian (utl_raw.length(l_domain), 2);  
  l_domain_max_length := int_to_raw_little_endian (utl_raw.length(l_domain), 2);  
  l_domain_buffer_offset := int_to_raw_little_endian (l_payload_start, 4);
  
  l_payload_start := l_payload_start + utl_raw.length(l_domain);  

  l_product_major_version := int_to_raw_little_endian (5, 1);
  l_product_minor_version := int_to_raw_little_endian (1, 1);
  l_product_build := int_to_raw_little_endian (2600, 2);
  
  l_version_reserved1 := int_to_raw_little_endian (0, 1);
  l_version_reserved2 := int_to_raw_little_endian (0, 1);
  l_version_reserved3 := int_to_raw_little_endian (0, 1);

  l_ntlm_revision_current := int_to_raw_little_endian (15, 1);
  
  l_return := utl_raw.concat(l_protocol,
                             l_type,
                             l_flags,
                             l_domain_length,
                             l_domain_max_length,
                             l_domain_buffer_offset,
                             l_workstation_length,
                             l_workstation_max_length,
                             l_workstation_buffer_offset,
                             l_product_major_version,
                             l_product_minor_version,
                             l_product_build);

  l_return := utl_raw.concat(l_return,
                             l_version_reserved1,
                             l_version_reserved2,
                             l_version_reserved3,
                             l_ntlm_revision_current);
  
  if utl_raw.length (l_return) <> l_body_length then
    raise_application_error(-20000, 'Length of negotiate message is ' || utl_raw.length(l_return) || ' (should be ' || l_body_length ||')');
  end if;
  
  l_return := utl_raw.concat (l_return, l_workstation, l_domain);
  
  l_returnvalue := utl_raw.cast_to_varchar2(l_return);
  l_returnvalue := encode_util_pkg.str_to_base64(l_returnvalue);
  l_returnvalue := replace(l_returnvalue, chr(13) || chr(10), '');
  
  return l_returnvalue;
  
end get_negotiate_message;
  

procedure parse_challenge_message (p_message2 in varchar2,
                                   p_server_challenge out raw,
                                   p_negotiate_flags out raw)
as
  l_message                       string_util_pkg.t_max_pl_varchar2;
  
  l_msg                           raw(4000);

  l_signature                     raw(8);
  l_msg_type                      raw(4);
  
  l_target_name_length            raw(2);
  l_target_name_maxlength         raw(2);
  l_target_name_offset            raw(4);
  
  l_target_name                   raw(100);
  
  l_negotiate_flags               raw(4);
  
  l_server_challenge              raw(8);
  l_reserved                      raw(8);
  
  l_target_info_length            raw(2);
  l_target_info_maxlength         raw(2);
  l_target_info_offset            raw(4);
  
  l_target_info                   raw(100);
  
  
begin

  /*
 
  Purpose:      Parse challenge message from server
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     31.05.2011  Created
 
  */
  
  l_msg := utl_encode.base64_decode(utl_raw.cast_to_raw(p_message2));
  
  l_signature := utl_raw.substr(l_msg, 1, 8);
  l_msg_type := utl_raw.substr(l_msg, 9, 4);

  l_target_name_length := utl_raw.substr(l_msg, 13, 2);
  l_target_name_maxlength := utl_raw.substr(l_msg, 15, 2);
  l_target_name_offset := utl_raw.substr(l_msg, 17, 4);
  
  -- using reverse because the flags are in little endian order?
  l_negotiate_flags := utl_raw.reverse(utl_raw.substr(l_msg, 21, 4));
  --l_negotiate_flags := utl_raw.substr(l_msg, 21, 4);
  
  l_server_challenge := utl_raw.substr(l_msg, 25, 8);
  l_reserved := utl_raw.substr(l_msg, 33, 8);
  
  l_target_info_length := utl_raw.substr(l_msg, 41, 2);
  l_target_info_maxlength := utl_raw.substr(l_msg, 43, 2);
  l_target_info_offset := utl_raw.substr(l_msg, 45, 4);
  
  debug_pkg.printf('Signature: "%1", Message Type: "%2", Negotiate Flags: "%3", Server Challenge: "%4"', l_signature, l_msg_type, l_negotiate_flags, l_server_challenge);
  
  p_server_challenge := l_server_challenge;
  p_negotiate_flags := l_negotiate_flags;

end parse_challenge_message;


function create_des_key (p_bytes in raw) return raw
as
  l_byte1                        raw(1);
  l_byte2                        raw(1);
  l_byte3                        raw(1);
  l_byte4                        raw(1);
  l_byte5                        raw(1);
  l_byte6                        raw(1);
  l_byte7                        raw(1);
  l_byte8                        raw(1);
  l_returnvalue                  raw(8);

  function raw2num(p_raw in raw) return number
  is
  begin 
    return utl_raw.cast_to_binary_integer(p_raw, utl_raw.little_endian);
  end;

  function get_8bit_mask return raw
  as
  begin
    return utl_raw.cast_from_binary_integer(255, utl_raw.little_endian);
  end get_8bit_mask;
    
begin

  /*
 
  Purpose:      create an 8-byte DES key from a 7-byte key
 
  Remarks:      insert a null bit after every seven bits (so 1010100 becomes 01010100)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */

  raw_util_pkg.set_endianness (utl_raw.little_endian);

  --debug_pkg.printf('input byte 1 = %1', raw2num(utl_raw.substr(p_bytes, 1, 1)));
  --debug_pkg.printf('input byte 2 = %1', raw2num(utl_raw.substr(p_bytes, 2, 1)));
  --debug_pkg.printf('input byte 3 = %1', raw2num(utl_raw.substr(p_bytes, 3, 1)));
  --debug_pkg.printf('input byte 4 = %1', raw2num(utl_raw.substr(p_bytes, 4, 1)));
  --debug_pkg.printf('input byte 5 = %1', raw2num(utl_raw.substr(p_bytes, 5, 1)));
  --debug_pkg.printf('input byte 6 = %1', raw2num(utl_raw.substr(p_bytes, 6, 1)));
  --debug_pkg.printf('input byte 7 = %1', raw2num(utl_raw.substr(p_bytes, 7, 1)));

  l_byte1 := utl_raw.substr(p_bytes, 1, 1);
  l_byte2 := utl_raw.substr( utl_raw.bit_or(utl_raw.bit_and(raw_util_pkg.bit_shift_left_raw (utl_raw.substr(p_bytes, 1, 1), 7), get_8bit_mask), raw_util_pkg.bit_shift_right_raw (utl_raw.substr(p_bytes, 2, 1), 1)) , 1, 1);
  l_byte3 := utl_raw.substr( utl_raw.bit_or(utl_raw.bit_and(raw_util_pkg.bit_shift_left_raw (utl_raw.substr(p_bytes, 2, 1), 6), get_8bit_mask), raw_util_pkg.bit_shift_right_raw (utl_raw.substr(p_bytes, 3, 1), 2)) , 1, 1);
  l_byte4 := utl_raw.substr( utl_raw.bit_or(utl_raw.bit_and(raw_util_pkg.bit_shift_left_raw (utl_raw.substr(p_bytes, 3, 1), 5), get_8bit_mask), raw_util_pkg.bit_shift_right_raw (utl_raw.substr(p_bytes, 4, 1), 3)) , 1, 1);
  l_byte5 := utl_raw.substr( utl_raw.bit_or(utl_raw.bit_and(raw_util_pkg.bit_shift_left_raw (utl_raw.substr(p_bytes, 4, 1), 4), get_8bit_mask), raw_util_pkg.bit_shift_right_raw (utl_raw.substr(p_bytes, 5, 1), 4)) , 1, 1);
  l_byte6 := utl_raw.substr( utl_raw.bit_or(utl_raw.bit_and(raw_util_pkg.bit_shift_left_raw (utl_raw.substr(p_bytes, 5, 1), 3), get_8bit_mask), raw_util_pkg.bit_shift_right_raw (utl_raw.substr(p_bytes, 6, 1), 5)) , 1, 1);
  l_byte7 := utl_raw.substr( utl_raw.bit_or(utl_raw.bit_and(raw_util_pkg.bit_shift_left_raw (utl_raw.substr(p_bytes, 6, 1), 2), get_8bit_mask), raw_util_pkg.bit_shift_right_raw (utl_raw.substr(p_bytes, 7, 1), 6)) , 1, 1);
  l_byte8 := utl_raw.substr( utl_raw.bit_and (raw_util_pkg.bit_shift_left_raw (utl_raw.substr(p_bytes, 7, 1), 1), get_8bit_mask), 1, 1);

  --debug_pkg.printf('output byte 1 = %1', raw2num(l_byte1));
  --debug_pkg.printf('output byte 2 = %1', raw2num(l_byte2));
  --debug_pkg.printf('output byte 3 = %1', raw2num(l_byte3));
  --debug_pkg.printf('output byte 4 = %1', raw2num(l_byte4));
  --debug_pkg.printf('output byte 5 = %1', raw2num(l_byte5));
  --debug_pkg.printf('output byte 6 = %1', raw2num(l_byte6));
  --debug_pkg.printf('output byte 7 = %1', raw2num(l_byte7));
  --debug_pkg.printf('output byte 8 = %1', raw2num(l_byte8));

  l_returnvalue := utl_raw.concat (l_byte1, l_byte2, l_byte3, l_byte4, l_byte5, l_byte6, l_byte7, l_byte8);

  return l_returnvalue;
    
end create_des_key;  


function get_lm_hashed_password_v1 (p_password in raw) return raw
as

  -- http://en.wikipedia.org/wiki/LM_hash - "The DES CipherMode should be set to ECB, and PaddingMode should be set to NONE."
  l_algorithm                    constant pls_integer := dbms_crypto.encrypt_des + dbms_crypto.chain_ecb + dbms_crypto.pad_none;

  l_user_pw_length               pls_integer;
  l_lm_password                  raw(255);
  l_magic_str                    constant raw(20) := utl_raw.cast_to_raw('KGS!@#$%'); -- page 57 in [MS-NLMP]

  l_low_key                      raw(8);
  l_high_key                     raw(8);
  l_low_hash                     raw(255);
  l_high_hash                    raw(255);

  l_returnvalue                  raw(2000);

begin

  /*
 
  Purpose:      create LanManager (LM) hashed password
 
  Remarks:      see http://en.wikipedia.org/wiki/LM_hash#Algorithm
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */

  l_lm_password := p_password;

  --debug_pkg.printf('user password byte 1 = %1', utl_raw.cast_to_varchar2(utl_raw.substr(l_lm_password, 1, 1)));

  l_user_pw_length := utl_raw.length (l_lm_password);
  --debug_pkg.printf('user password byte length = %1', l_user_pw_length);

  -- pad the password length to 14 bytes
  if l_user_pw_length < 14 then
    for i in 1..(14-l_user_pw_length) loop
      l_lm_password := utl_raw.concat(l_lm_password, hextoraw('0'));
    end loop;
  end if;
  --debug_pkg.printf('new byte length = %1', utl_raw.length (l_lm_password));
  l_lm_password := utl_raw.substr(l_lm_password, 1, 14);

  -- do hash
  l_low_key := create_des_key (utl_raw.substr(l_lm_password, 1, 7));
  l_high_key := create_des_key (utl_raw.substr(l_lm_password, 8, 7));
  l_low_hash := dbms_crypto.encrypt (l_magic_str, l_algorithm, l_low_key);
  l_high_hash := dbms_crypto.encrypt (l_magic_str, l_algorithm, l_high_key);

  l_returnvalue := utl_raw.concat (l_low_hash, l_high_hash);
  --debug_pkg.printf('LM hashed password returnvalue (base64 encoded for readability) = %1', utl_raw.cast_to_varchar2(utl_encode.base64_encode(l_returnvalue)));

  return l_returnvalue;

end get_lm_hashed_password_v1;


function get_nt_hashed_password_v1 (p_password in varchar2) return raw

as
  l_returnvalue raw(4000);
begin

  /*
 
  Purpose:      Get NT hashed password
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     01.06.2011  Created
 
  */
  
  l_returnvalue := dbms_crypto.hash(utl_raw.cast_to_raw(convert (p_password, 'AL16UTF16LE')), dbms_crypto.HASH_MD4);

  return l_returnvalue;
  
end get_nt_hashed_password_v1;


function get_nt_hashed_password_v2 (p_password in varchar2,
                                    p_user in varchar2,
                                    p_domain in varchar2) return raw

as
  l_returnvalue raw(4000);
begin

  /*
 
  Purpose:      Get NT hashed password
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     01.06.2011  Created
 
  */
  
  l_returnvalue := get_nt_hashed_password_v1 (p_password);

  l_returnvalue := dbms_crypto.mac(utl_raw.cast_to_raw(convert(upper(p_user) || p_domain, 'AL16UTF16LE')), dbms_crypto.HMAC_MD5, l_returnvalue);
  
  return l_returnvalue;
  
end get_nt_hashed_password_v2;


function get_response (p_password_hash in raw,
                       p_server_challenge in raw) return raw
as
  l_raw                          raw(21);
  l_password_hash_length         pls_integer;
  l_password_hash                raw(21);
  l_server_challenge             raw(8);
  
  l_hash1                        raw(8);
  l_hash2                        raw(8);
  l_hash3                        raw(8);
 
  l_algorithm                    constant pls_integer := dbms_crypto.encrypt_des + dbms_crypto.chain_ecb + dbms_crypto.pad_none;
 
  l_returnvalue                  raw (24);
  
begin

  /*
 
  Purpose:      get LM response
 
  Remarks:      generates the LM response given a 16-byte password hash and
                the 8 byte server challenge from the Type-2 message
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     01.06.2011  Created
  MBR     16.06.2011  Fixed padding
 
  */
  
  l_password_hash_length := utl_raw.length (p_password_hash);
  --debug_pkg.printf('get_response: password hash length = %1', l_password_hash_length);
  
  if l_password_hash_length < 21 then
    l_password_hash := utl_raw.substr(p_password_hash, 1, least(21, l_password_hash_length));
    for i in 1..(21-l_password_hash_length) loop
      l_password_hash := utl_raw.concat(l_password_hash, hextoraw('0'));
    end loop;
  end if;

  --debug_pkg.printf('new byte length = %1', utl_raw.length (l_password_hash));

  l_password_hash := utl_raw.substr(l_password_hash, 1, 21);

  l_server_challenge := utl_raw.substr(p_server_challenge, 1, 8);
  
  l_hash1 := dbms_crypto.encrypt(l_server_challenge, l_algorithm, create_des_key(utl_raw.substr(l_password_hash, 1, 7))); 
  l_hash2 := dbms_crypto.encrypt(l_server_challenge, l_algorithm, create_des_key(utl_raw.substr(l_password_hash, 8, 7)));
  l_hash3 := dbms_crypto.encrypt(l_server_challenge, l_algorithm, create_des_key(utl_raw.substr(l_password_hash, 15, 7)));

  l_returnvalue := utl_raw.concat(l_hash1, l_hash2, l_hash3);
  
  return l_returnvalue;
  
end get_response;


procedure calc_response_2sr (p_password_hash in raw,
                             p_server_challenge in raw,
                             p_nt_challenge out raw,
                             p_lm_challenge out raw)
as
  l_client_challenge raw(16);
  l_sess             raw(4000);
begin

  /*
 
  Purpose:      Calculate response for extended security
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     06.06.2011  Created
 
  */

  l_client_challenge := hextoraw('AAAAAAAAAAAAAAAA');
  --l_client_challenge := hextoraw('39e3f4cd59c5d860');
  --l_client_challenge := hextoraw('5487e2f40422146a');
  
  -- generating random client challenge of 16 bytes
  --l_client_challenge := utl_raw.concat(utl_raw.cast_from_binary_integer(floor(dbms_random.value(1, 2147483648))), utl_raw.cast_from_binary_integer(floor(dbms_random.value(1, 2147483648)))); 
  
  p_lm_challenge := utl_raw.concat (l_client_challenge, hextoraw('00000000000000000000000000000000'));
  l_sess := dbms_crypto.hash(utl_raw.concat(p_server_challenge, l_client_challenge), dbms_crypto.HASH_MD5);
  
  p_nt_challenge := get_response (p_password_hash, utl_raw.substr(l_sess, 1, 8));
  debug_pkg.printf('Challenge: "%3", NT: "%1", LM: ="%2", Sess: "%4", Client Challenge: "%5"', p_nt_challenge, p_lm_challenge, utl_raw.concat(p_server_challenge, p_lm_challenge), l_sess, l_client_challenge);
  
end calc_response_2sr;                                    
  

function get_authenticate_message (p_username in varchar2,
                                   p_password in varchar2,
                                   p_server_challenge in raw,
                                   p_negotiate_flags in raw) return varchar2
as
  l_returnvalue                   string_util_pkg.t_max_pl_varchar2;

  l_body_length                   number;
  l_payload_start                 number;
  
  l_is_unicode                    boolean;
  l_negotiate_ext_sec             boolean;

  l_workstation_str               varchar2(500);
  l_domain_str                    varchar2(500);
  l_user_str                      varchar2(500);
  
  --l_protocol                      raw(8);
  l_protocol                      raw(16);
  l_workstation                   raw(32);
  l_domain                        raw(32);
  l_username                      raw(32); -- was: raw(16)
  
  l_password_hash                 raw(32);
  l_client_challenge              raw(8);
  
  l_type                          raw(4);
  l_flags                         raw(4);
  
  l_workstation_length            raw(2);
  l_workstation_max_length        raw(2);
  l_workstation_buffer_offset     raw(4);
  
  l_domain_length                 raw(2);
  l_domain_max_length             raw(2);
  l_domain_buffer_offset          raw(4);

  l_username_length               raw(2);
  l_username_max_length           raw(2);
  l_username_buffer_offset        raw(4);
  
  l_lm_challenge_response         raw(100);
  l_nt_challenge_response         raw(100);
  l_enc_rand_session_key          raw(100);

  l_lm_challenge_length           raw(2);
  l_lm_challenge_max_length       raw(2);
  l_lm_challenge_buffer_offset    raw(4);

  l_nt_challenge_length           raw(2);
  l_nt_challenge_max_length       raw(2);
  l_nt_challenge_buffer_offset    raw(4);

  l_encrandsesskey_length         raw(2);
  l_encrandsesskey_max_length     raw(2);
  l_encrandsesskey_buffer_offset  raw(4);
  
  l_product_major_version         raw(1);
  l_product_minor_version         raw(1);
  l_product_build                 raw(2);
  
  l_version_reserved1             raw(1);
  l_version_reserved2             raw(1);
  l_version_reserved3             raw(1);

  l_ntlm_revision_current         raw(1);
  
  l_return                        raw(2000);  

  l_lm_hashed_password            raw(2000);

begin

  /*
 
  Purpose:      Get authenticate (type 3) message
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     01.06.2011  Created
 
  */

  l_body_length := 72;
  l_payload_start := l_body_length;
  
  parse_username (p_username, l_domain_str, l_user_str);
  l_workstation_str := get_workstation_name;
  
  debug_pkg.printf('username = %1, domain = %2, workstation = %3', l_user_str, l_domain_str, l_workstation_str);

  l_flags := bit_or_multi (m_NTLM_NegotiateUnicode,
                           m_NTLM_RequestTarget,
                           m_NTLM_NegotiateNTLM,
                           m_NTLM_NegotiateAlwaysSign,
                           m_NTLM_NegotiateExtendedSec,
                           m_NTLM_NegotiateTargetInfo,
                           m_NTLM_NegotiateVersion,
                           m_NTLM_Negotiate128,
                           m_NTLM_Negotiate56);
  
  -- need to convert flags to little endian
  l_flags := int_to_raw_little_endian(utl_raw.cast_to_binary_integer(l_flags), 4);
  
  l_lm_challenge_response := get_response (get_lm_hashed_password_v1(utl_raw.cast_to_raw(upper(p_password))), p_server_challenge);
  l_nt_challenge_response := get_response (get_nt_hashed_password_v1(p_password), p_server_challenge);
  l_enc_rand_session_key := null;
  
  if utl_raw.bit_and (p_negotiate_flags, m_NTLM_NegotiateUnicode) = m_NTLM_NegotiateUnicode then
    l_is_unicode := true;
  else
    l_is_unicode := false;
  end if;

  if utl_raw.bit_and (p_negotiate_flags, m_NTLM_NegotiateExtendedSec) = m_NTLM_NegotiateExtendedSec then
    l_negotiate_ext_sec := true;
  else
    l_negotiate_ext_sec := false;
  end if;
  
  if l_is_unicode then
    --debug_pkg.printf('l_is_unicode is TRUE...');
    l_workstation_str := convert (l_workstation_str, 'AL16UTF16LE');
    l_domain_str := convert (l_domain_str, 'AL16UTF16LE');
    l_user_str := convert (l_user_str, 'AL16UTF16LE');
    --l_enc_rand_session_key := convert (utl_raw.cast_to_varchar2(l_enc_rand_session_key), 'AL16UTF16LE');
  end if;

  if l_negotiate_ext_sec then
    l_password_hash := get_nt_hashed_password_v1 (p_password);
    calc_response_2sr (l_password_hash, p_server_challenge, l_nt_challenge_response, l_lm_challenge_response);
  end if;

  --l_protocol := utl_raw.cast_to_raw('NTLMSSP' || chr(256));
  l_protocol := utl_raw.cast_to_raw('NTLMSSP' || chr(0));
  l_type := int_to_raw_little_endian(3, 4); --- Type 3
  
  l_workstation := utl_raw.cast_to_raw(l_workstation_str);
  l_domain := utl_raw.cast_to_raw(l_domain_str);
  l_username := utl_raw.cast_to_raw(l_user_str);

  l_domain_length := int_to_raw_little_endian(utl_raw.length(l_domain), 2);  
  l_domain_max_length := int_to_raw_little_endian(utl_raw.length(l_domain), 2);  
  l_domain_buffer_offset := int_to_raw_little_endian(l_payload_start, 4);
  l_payload_start := l_payload_start + utl_raw.length(l_domain);  

  l_username_length := int_to_raw_little_endian(utl_raw.length(l_username), 2);  
  l_username_max_length := int_to_raw_little_endian(utl_raw.length(l_username), 2);  
  l_username_buffer_offset := int_to_raw_little_endian(l_payload_start, 4);
  l_payload_start := l_payload_start + utl_raw.length(l_username);  
  
  l_workstation_length := int_to_raw_little_endian(utl_raw.length(l_workstation), 2);
  l_workstation_max_length := int_to_raw_little_endian(utl_raw.length(l_workstation), 2);
  l_workstation_buffer_offset := int_to_raw_little_endian(l_payload_start, 4);
  l_payload_start := l_payload_start + utl_raw.length(l_workstation);

  l_lm_challenge_length := int_to_raw_little_endian(utl_raw.length(l_lm_challenge_response), 2);
  l_lm_challenge_max_length := int_to_raw_little_endian(utl_raw.length(l_lm_challenge_response), 2);
  l_lm_challenge_buffer_offset := int_to_raw_little_endian(l_payload_start, 4);
  l_payload_start := l_payload_start + utl_raw.length(l_lm_challenge_response);

  l_nt_challenge_length := int_to_raw_little_endian(utl_raw.length(l_nt_challenge_response), 2);
  l_nt_challenge_max_length := int_to_raw_little_endian(utl_raw.length(l_nt_challenge_response), 2);
  l_nt_challenge_buffer_offset := int_to_raw_little_endian(l_payload_start, 4);
  l_payload_start := l_payload_start + utl_raw.length(l_nt_challenge_response);
  
  --l_encrandsesskey_length := int_to_raw_little_endian(utl_raw.length(l_enc_rand_session_key), 2);
  l_encrandsesskey_length := int_to_raw_little_endian(0, 2);
  --l_encrandsesskey_max_length := int_to_raw_little_endian(utl_raw.length(l_enc_rand_session_key), 2);
  l_encrandsesskey_max_length := int_to_raw_little_endian(0, 2);
  l_encrandsesskey_buffer_offset := int_to_raw_little_endian(l_payload_start, 4);
  --l_payload_start := l_payload_start + utl_raw.length(l_enc_rand_session_key);
  l_payload_start := l_payload_start + 0;
  
  l_product_major_version := int_to_raw_little_endian(5, 1);
  l_product_minor_version := int_to_raw_little_endian(1, 1);
  l_product_build := int_to_raw_little_endian(2600, 2);
  
  l_version_reserved1 := int_to_raw_little_endian(0, 1);
  l_version_reserved2 := int_to_raw_little_endian(0, 1);
  l_version_reserved3 := int_to_raw_little_endian(0, 1);

  l_ntlm_revision_current := int_to_raw_little_endian(15, 1);

  l_return := utl_raw.concat(l_protocol,
                             l_type,
                             l_lm_challenge_length,
                             l_lm_challenge_max_length,
                             l_lm_challenge_buffer_offset,
                             l_nt_challenge_length,
                             l_nt_challenge_max_length,
                             l_nt_challenge_buffer_offset,
                             l_domain_length,
                             l_domain_max_length,
                             l_domain_buffer_offset);

  l_return := utl_raw.concat (l_return,
                              l_username_length,
                              l_username_max_length,
                              l_username_buffer_offset,
                              l_workstation_length,
                              l_workstation_max_length,
                              l_workstation_buffer_offset,
                              l_encrandsesskey_length,
                              l_encrandsesskey_max_length,
                              l_encrandsesskey_buffer_offset);

  l_return := utl_raw.concat (l_return,
                              l_flags,
                              l_product_major_version,
                              l_product_minor_version,
                              l_product_build,
                              l_version_reserved1,
                              l_version_reserved2,
                              l_version_reserved3,
                              l_ntlm_revision_current);

  if utl_raw.length (l_return) <> l_body_length then
    raise_application_error (-20000, 'Length of authenticate message is ' || utl_raw.length(l_return) || ' (should be ' || l_body_length ||')');
  end if;
  
  --l_return := utl_raw.concat (l_return, l_domain, l_username, l_workstation, l_lm_challenge_response, l_nt_challenge_response, l_enc_rand_session_key);
  --l_return := utl_raw.concat (l_return, l_domain, l_username, l_workstation, l_lm_challenge_response, l_nt_challenge_response);
  l_return := utl_raw.concat (l_return, l_domain, l_username, l_workstation, l_lm_challenge_response, l_nt_challenge_response);
  
  --l_return := utl_raw.concat (l_domain, l_username, l_workstation, l_lm_challenge_response, l_nt_challenge_response);
  
  l_returnvalue := utl_raw.cast_to_varchar2(l_return);
  l_returnvalue := encode_util_pkg.str_to_base64(l_returnvalue);
  l_returnvalue := replace(l_returnvalue, chr(13) || chr(10), '');
  
  return l_returnvalue;
  
end get_authenticate_message;

  

end ntlm_util_pkg;
/

