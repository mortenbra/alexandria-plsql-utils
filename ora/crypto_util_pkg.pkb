create or replace package body crypto_util_pkg
as

  /*

  Purpose:    Package handles encryption/decryption

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     20.01.2011  Created
  
  */

  g_encryption_type_aes          constant pls_integer := dbms_crypto.encrypt_aes256 + dbms_crypto.chain_cbc + dbms_crypto.pad_pkcs5;


function encrypt_aes256 (p_blob in blob,
                         p_key in varchar2) return blob
as
  l_key_raw                      raw(32);
  l_returnvalue                  blob;
begin

  /*

  Purpose:    encrypt blob

  Remarks:    p_key should be 32 characters (256 bits / 8 = 32 bytes)

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     20.01.2011  Created
  
  */
  
  l_key_raw := utl_raw.cast_to_raw (p_key);
  
  dbms_lob.createtemporary (l_returnvalue, false);

  dbms_crypto.encrypt (l_returnvalue, p_blob, g_encryption_type_aes, l_key_raw);

  return l_returnvalue;

end encrypt_aes256;


function decrypt_aes256 (p_blob in blob,
                         p_key in varchar2) return blob
as
  l_key_raw                      raw(32);
  l_returnvalue                  blob;
begin

  /*

  Purpose:    decrypt blob

  Remarks:    p_key should be 32 characters (256 bits / 8 = 32 bytes)

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     20.01.2011  Created
  
  */

  l_key_raw := utl_raw.cast_to_raw (p_key);
  
  dbms_lob.createtemporary (l_returnvalue, false);

  dbms_crypto.decrypt (l_returnvalue, p_blob, g_encryption_type_aes, l_key_raw);

  return l_returnvalue;

end decrypt_aes256;


end crypto_util_pkg;
/


