create or replace package body sql_util_pkg
as

  /*

  Purpose:    Package contains various SQL utilities

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     01.01.2008  Created
  
  */


function make_rows (p_number_of_rows in number) return t_num_array pipelined
as
begin

  /*

  Purpose:    make specified number of rows

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     01.01.2008  Created
  
  */


  for i in 1 .. p_number_of_rows loop
    pipe row (i);
  end loop;

  return;

end make_rows;


function make_rows (p_start_with in number,
                    p_end_with in number) return t_num_array pipelined
as
begin

  /*

  Purpose:    make rows in specified range

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     01.01.2008  Created
  
  */

  for i in p_start_with .. p_end_with loop
    pipe row (i);
  end loop;

  return;

end make_rows;


--function clob_to_blob (p_clob in clob) return blob
--as
--  l_pos         pls_integer := 1;
--  l_buffer      raw(32767);
--  l_lob_len     pls_integer := dbms_lob.getlength(p_clob);
--  l_returnvalue blob;
--begin

--  /*

--  Purpose:    convert clob to blob

--  Remarks:    see http://forums.oracle.com/forums/thread.jspa?threadID=491821

--  Who     Date        Description
--  ------  ----------  -------------------------------------
--  MBR     01.01.2008  Created
--  
--  */

--  dbms_lob.createtemporary(l_returnvalue, false);
--  dbms_lob.open(l_returnvalue, dbms_lob.lob_readwrite);

--  loop

--    l_buffer := utl_raw.cast_to_raw (dbms_lob.substr(p_clob, 16000, l_pos));

--    if utl_raw.length (l_buffer) > 0 then
--      dbms_lob.writeappend(l_returnvalue, utl_raw.length(l_buffer), l_buffer);
--    end if;

--    l_pos := l_pos + 16000;
--    exit when l_pos > l_lob_len;
--    
--  end loop;

--  return l_returnvalue;

--end clob_to_blob;


function clob_to_blob (p_clob in clob) return blob
as
 l_returnvalue   blob;
 l_dest_offset   integer := 1;
 l_source_offset integer := 1;
 l_lang_context  integer := dbms_lob.default_lang_ctx;
 l_warning       integer := dbms_lob.warn_inconvertible_char;
BEGIN

  /*

  Purpose:    convert clob to blob

  Remarks:    see http://www.dbforums.com/oracle/1624851-clob-blob.html

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.01.2011  Created
  
  */

  dbms_lob.createtemporary (l_returnvalue, true);
  
  dbms_lob.converttoblob
  (
   dest_lob    => l_returnvalue,
   src_clob    => p_clob,
   amount      => dbms_lob.getlength(p_clob),
   dest_offset => l_dest_offset,
   src_offset  => l_source_offset,
   blob_csid   => dbms_lob.default_csid,
   lang_context=> l_lang_context,
   warning     => l_warning
  );

  return l_returnvalue;
  
end clob_to_blob;


function blob_to_clob (p_blob in blob) return clob
as
 l_returnvalue   clob;
 l_dest_offset   integer := 1;
 l_source_offset integer := 1;
 l_lang_context  integer := dbms_lob.default_lang_ctx;
 l_warning       integer := dbms_lob.warn_inconvertible_char;
BEGIN

  /*

  Purpose:    convert blob to clob

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.01.2011  Created
  
  */

  dbms_lob.createtemporary (l_returnvalue, true);
  
  dbms_lob.converttoclob
  (
   dest_lob    => l_returnvalue,
   src_blob    => p_blob,
   amount      => dbms_lob.lobmaxsize,
   dest_offset => l_dest_offset,
   src_offset  => l_source_offset,
   blob_csid   => dbms_lob.default_csid,
   lang_context=> l_lang_context,
   warning     => l_warning
  );

  return l_returnvalue;
  
end blob_to_clob;


end sql_util_pkg;
/

