create or replace package body encode_util_pkg
as
 
  /*
 
  Purpose:      Package contains utility functions related to encoding/decoding (of strings)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.05.2011  Created
 
  */
 
 
function str_to_base64 (p_str in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      encode string using base64
 
  Remarks:      http://stackoverflow.com/questions/3804279/base64-encoding-and-decoding-in-oracle/3806265#3806265
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.05.2011  Created
 
  */
  
  l_returnvalue := utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_str)));
 
  return l_returnvalue;
 
end str_to_base64;
 
 
function clob_to_base64 (p_clob in clob) return clob
as
  l_pos            pls_integer := 1;
  l_buffer         varchar2 (32767);
  l_lob_len        integer := dbms_lob.getlength (p_clob);
  l_width          pls_integer := (76 / 4 * 3)-9;
  l_returnvalue    clob;
begin
 
  /*
 
  Purpose:      encode clob using base64
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.05.2011  Created
 
  */

  if p_clob is not null then

    dbms_lob.createtemporary (l_returnvalue, true);
    dbms_lob.open (l_returnvalue, dbms_lob.lob_readwrite);
    
    while (l_pos < l_lob_len) loop
      l_buffer := utl_raw.cast_to_varchar2 (utl_encode.base64_encode (dbms_lob.substr (p_clob, l_width, l_pos)));
      dbms_lob.writeappend (l_returnvalue, length (l_buffer), l_buffer);
      l_pos := l_pos + l_width;
    end loop;
    
  end if;
 
  return l_returnvalue;
 
end clob_to_base64;
 
 
function blob_to_base64 (p_blob in blob) return clob
as
  l_pos         pls_integer := 1;
  l_buffer      varchar2 (32767);
  l_lob_len     integer := dbms_lob.getlength (p_blob);
  l_width       pls_integer := (76 / 4 * 3)-9;
  l_returnvalue clob;
begin
 
  /*
 
  Purpose:      encode blob using base64
 
  Remarks:      based on Jason Straub's blob2clobbase64 in package flex_ws_api (aka apex_web_service)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.05.2011  Created
 
  */

  dbms_lob.createtemporary (l_returnvalue, true);
  dbms_lob.open (l_returnvalue, dbms_lob.lob_readwrite);

  while (l_pos < l_lob_len) loop
    l_buffer := utl_raw.cast_to_varchar2 (utl_encode.base64_encode (dbms_lob.substr (p_blob, l_width, l_pos)));
    dbms_lob.writeappend (l_returnvalue, length (l_buffer), l_buffer);
    l_pos := l_pos + l_width;
  end loop;
 
  return l_returnvalue;
 
end blob_to_base64;


function base64_to_str (p_str in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      decode base64-encoded string
 
  Remarks:      http://stackoverflow.com/questions/3804279/base64-encoding-and-decoding-in-oracle/3806265#3806265
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.05.2011  Created
 
  */
 
  l_returnvalue := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(p_str)));

  return l_returnvalue;
 
end base64_to_str;
 
 
function base64_to_clob (p_clob in varchar2) return clob
as

  l_pos            pls_integer := 1;
  l_buffer         raw(36);
  l_buffer_str     varchar2(2000);
  l_lob_len        integer := dbms_lob.getlength (p_clob);
  l_width          pls_integer := (76 / 4 * 3)-9;
  l_returnvalue    clob;
begin
 
  /*
 
  Purpose:      decode base64-encoded clob
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.05.2011  Created
 
  */
 
  if p_clob is not null then

    dbms_lob.createtemporary (l_returnvalue, true);
    dbms_lob.open (l_returnvalue, dbms_lob.lob_readwrite);
    
    while (l_pos < l_lob_len) loop
      l_buffer := utl_encode.base64_decode(utl_raw.cast_to_raw(dbms_lob.substr (p_clob, l_width, l_pos)));
      l_buffer_str := utl_raw.cast_to_varchar2(l_buffer);
      dbms_lob.writeappend (l_returnvalue, length(l_buffer_str), l_buffer_str);
      l_pos := l_pos + l_width;
    end loop;
    
  end if;

  return l_returnvalue;
 
end base64_to_clob;
 
 
function base64_to_blob (p_clob in clob) return blob
as
  l_pos         pls_integer := 1;
  l_buffer      raw(36);
  l_lob_len     integer := dbms_lob.getlength (p_clob);
  l_width       pls_integer := (76 / 4 * 3)-9;
  l_returnvalue blob;
begin
 
  /*
 
  Purpose:      decode base64-encoded clob to blob
 
  Remarks:      based on Jason Straub's clobbase642blob in package flex_ws_api (aka apex_web_service)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.05.2011  Created
 
  */
 
  dbms_lob.createtemporary (l_returnvalue, true);
  dbms_lob.open (l_returnvalue, dbms_lob.lob_readwrite);

  while (l_pos < l_lob_len) loop
    l_buffer := utl_encode.base64_decode(utl_raw.cast_to_raw(dbms_lob.substr (p_clob, l_width, l_pos)));
    dbms_lob.writeappend (l_returnvalue, utl_raw.length(l_buffer), l_buffer);
    l_pos := l_pos + l_width;
  end loop;

  return l_returnvalue;
 
end base64_to_blob;

 
end encode_util_pkg;
/
 


