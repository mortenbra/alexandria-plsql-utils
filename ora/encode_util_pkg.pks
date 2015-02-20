create or replace package encode_util_pkg
as
 
  /*
 
  Purpose:      Package contains utility functions related to encoding/decoding (of strings)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.05.2011  Created
 
  */
 
 
  -- encode string using base64
  function str_to_base64 (p_str in varchar2) return varchar2;
 
  -- encode clob using base64
  function clob_to_base64 (p_clob in clob) return clob;
 
  -- encode blob using base64
  function blob_to_base64 (p_blob in blob) return clob;

  -- decode base64-encoded string
  function base64_to_str (p_str in varchar2) return varchar2;
 
  -- decode base64-encoded clob
  function base64_to_clob (p_clob in varchar2) return clob;
 
  -- decode base64-encoded clob to blob
  function base64_to_blob (p_clob in clob) return blob;
 
end encode_util_pkg;
/

