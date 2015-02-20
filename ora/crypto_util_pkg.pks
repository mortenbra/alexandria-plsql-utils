create or replace package crypto_util_pkg
as

  /*

  Purpose:    Package handles encryption/decryption

  Remarks:    see http://download.oracle.com/docs/cd/B14117_01/network.101/b10773/apdvncrp.htm
              see "Effective Oracle Database 10g Security" by David Knox (McGraw Hill 2004)

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     20.01.2011  Created
  
  */


  -- encrypt blob
  function encrypt_aes256 (p_blob in blob,
                           p_key in varchar2) return blob;

  -- decrypt blob
  function decrypt_aes256 (p_blob in blob,
                           p_key in varchar2) return blob;


end crypto_util_pkg;
/

