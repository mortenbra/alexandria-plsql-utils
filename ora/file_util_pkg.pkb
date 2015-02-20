create or replace package body file_util_pkg
as

  /*
 
  Purpose:      Package contains file utilities 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2005  Created
  MBR     18.01.2011  Added blob/clob operations
 
  */


function resolve_filename (p_dir in varchar2,
                           p_file_name in varchar2,
                           p_os in varchar2 := g_os_windows) return varchar2
as
  l_returnvalue t_file_name;
begin

  /*
 
  Purpose:      resolve filename, ie. properly concatenate dir and filename 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2005  Created
 
  */
  
  if lower(p_os) = g_os_windows then

    if substr(p_dir,-1) = g_dir_sep_win then
      l_returnvalue:=p_dir || p_file_name;
    else
      if p_dir is not null then
        l_returnvalue:=p_dir || g_dir_sep_win || p_file_name;
      else
        l_returnvalue:=p_file_name;
      end if;
    end if;

  elsif lower(p_os) = g_os_unix then

    if substr(p_dir,-1) = g_dir_sep_unix then
      l_returnvalue:=p_dir || p_file_name;
    else
      if p_dir is not null then
        l_returnvalue:=p_dir || g_dir_sep_unix || p_file_name;
      else
        l_returnvalue:=p_file_name;
      end if;
    end if;
  
  else
    l_returnvalue:=null;
  end if;
  
  return l_returnvalue;

end resolve_filename;
                             

function extract_filename (p_file_name in varchar2,
                           p_os in varchar2 := g_os_windows) return varchar2
as
  l_returnvalue    t_file_name;
  l_dir_sep        t_dir_sep;
  l_dir_sep_pos    pls_integer;
begin

  /*
 
  Purpose:      return the filename portion of the full file name 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2005  Created
 
  */

  if lower(p_os) = g_os_windows then
    l_dir_sep:=g_dir_sep_win;
  elsif lower(p_os) = g_os_unix then
    l_dir_sep:=g_dir_sep_unix;
  end if;
  
  if lower(p_os) in (g_os_windows, g_os_unix) then

    l_dir_sep_pos:=instr(p_file_name, l_dir_sep, -1);
    if l_dir_sep_pos = 0 then
      -- no directory found
      l_returnvalue:=p_file_name;
    else
      -- copy filename part
      l_returnvalue:=string_util_pkg.copy_str(p_file_name, l_dir_sep_pos + 1);
    end if;
  
  else
    l_returnvalue:=null;
  end if;

  return l_returnvalue;

end extract_filename;


function get_file_ext (p_file_name in varchar2) return varchar2
as
  l_sep_pos     pls_integer;
  l_returnvalue t_file_name;
begin

  /*
 
  Purpose:      get file extension 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2005  Created
 
  */
  
  l_sep_pos:=instr(p_file_name, g_file_ext_sep, -1);
  
  if l_sep_pos = 0 then
    -- no extension found
    l_returnvalue:=null;
  else
    -- copy extension
    l_returnvalue:=string_util_pkg.copy_str(p_file_name, l_sep_pos + 1);
  end if;

  return l_returnvalue;

end get_file_ext;


function strip_file_ext (p_file_name in varchar2) return varchar2
as
  l_sep_pos      pls_integer;
  l_file_ext     t_file_name;
  l_returnvalue  t_file_name;
begin

  /*
 
  Purpose:      strip file extension 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2005  Created
 
  */

  l_file_ext:=get_file_ext (p_file_name);

  if l_file_ext is not null then
    l_sep_pos:=instr(p_file_name, g_file_ext_sep || l_file_ext, -1);
    -- copy everything except extension
    if l_sep_pos > 0 then
      l_returnvalue:=string_util_pkg.copy_str(p_file_name, 1, l_sep_pos - 1);
    else
      l_returnvalue:=p_file_name;
    end if;
  else
    l_returnvalue:=p_file_name;
  end if;

  return l_returnvalue;

end strip_file_ext;


function get_filename_str (p_str in varchar2,
                           p_extension in varchar2 := null) return varchar2
as
  l_returnvalue t_file_name;
begin

  /*

  Purpose:    returns string suitable for file names, ie. no whitespace or special path characters

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     16.11.2009  Created
  
  */
  
  l_returnvalue := replace(replace(replace(replace(trim(p_str), ' ', '_'), '\', '_'), '/', '_'), ':', '');
  
  if p_extension is not null then
    l_returnvalue := l_returnvalue || '.' || p_extension;
  end if;
  
  return l_returnvalue;

end get_filename_str;


function get_blob_from_file (p_directory_name in varchar2,
                             p_file_name in varchar2) return blob
as
  l_bfile          bfile;
  l_returnvalue    blob;
begin

  /*
 
  Purpose:      Get blob from file
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     18.01.2011  Created
 
  */

  dbms_lob.createtemporary (l_returnvalue, false);
  l_bfile := bfilename (p_directory_name, p_file_name);
  dbms_lob.fileopen (l_bfile, dbms_lob.file_readonly);
  dbms_lob.loadfromfile (l_returnvalue, l_bfile, dbms_lob.getlength(l_bfile));
  dbms_lob.fileclose (l_bfile);

  return l_returnvalue;

exception
  when others then
    if dbms_lob.fileisopen (l_bfile) = 1 then
      dbms_lob.fileclose (l_bfile);
    end if;
    dbms_lob.freetemporary(l_returnvalue);
    raise;

end get_blob_from_file;


function get_clob_from_file (p_directory_name in varchar2,
                             p_file_name in varchar2) return clob
as
  l_bfile          bfile;
  l_returnvalue    clob;
begin

  /*
 
  Purpose:      Get clob from file
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     18.01.2011  Created
 
  */

  dbms_lob.createtemporary (l_returnvalue, false);
  l_bfile := bfilename (p_directory_name, p_file_name);
  dbms_lob.fileopen (l_bfile, dbms_lob.file_readonly);
  dbms_lob.loadfromfile (l_returnvalue, l_bfile, dbms_lob.getlength(l_bfile));
  dbms_lob.fileclose (l_bfile);

  return l_returnvalue;

exception
  when others then
    if dbms_lob.fileisopen (l_bfile) = 1 then
      dbms_lob.fileclose (l_bfile);
    end if;
    dbms_lob.freetemporary(l_returnvalue);
    raise;

end get_clob_from_file;


procedure save_blob_to_file (p_directory_name in varchar2,
                             p_file_name in varchar2,
                             p_blob in blob)
as
  l_file      utl_file.file_type;
  l_buffer    raw(32767);
  l_amount    binary_integer := 32767;
  l_pos       integer := 1;
  l_blob_len  integer;
begin

  /*
 
  Purpose:      save blob to file
 
  Remarks:      see http://www.oracle-base.com/articles/9i/ExportBlob9i.php
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     20.01.2011  Created
 
  */

  l_blob_len := dbms_lob.getlength (p_blob);
  
  l_file := utl_file.fopen (p_directory_name, p_file_name, g_file_mode_write_byte, 32767);

  while l_pos < l_blob_len loop
    dbms_lob.read (p_blob, l_amount, l_pos, l_buffer);
    utl_file.put_raw (l_file, l_buffer, true);
    l_pos := l_pos + l_amount;
  end loop;
  
  utl_file.fclose (l_file);
  
exception
  when others then
    if utl_file.is_open (l_file) then
      utl_file.fclose (l_file);
    end if;
    raise;  

end save_blob_to_file;  


procedure save_clob_to_file (p_directory_name in varchar2,
                             p_file_name in varchar2,
                             p_clob in clob)
as
  l_file      utl_file.file_type;
  l_buffer    varchar2(32767);
  l_amount    binary_integer := 8000;
  l_pos       integer := 1;
  l_clob_len  integer;
begin

  /*
 
  Purpose:      save clob to file
 
  Remarks:      see http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:744825627183
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     20.01.2011  Created
  MBR     04.03.2011  Fixed issue with ORA-06502 on dbms_lob.read (reduced l_amount from 32k to 8k)
 
  */
  
  l_clob_len := dbms_lob.getlength (p_clob);
  
  l_file := utl_file.fopen (p_directory_name, p_file_name, g_file_mode_write_text, 32767);

  while l_pos < l_clob_len loop
    dbms_lob.read (p_clob, l_amount, l_pos, l_buffer);
    utl_file.put (l_file, l_buffer);
    utl_file.fflush (l_file);
    l_pos := l_pos + l_amount;
  end loop;

  utl_file.fclose (l_file);

exception
  when others then
    if utl_file.is_open (l_file) then
      utl_file.fclose (l_file);
    end if;
    raise;  

end save_clob_to_file;  


procedure save_clob_to_file_raw (p_directory_name in varchar2,
                                 p_file_name in varchar2,
                                 p_clob in clob)
as
  l_file       utl_file.file_type;
  l_chunk_size pls_integer := 3000;
begin

  /*
 
  Purpose:      save clob to file
 
  Remarks:      see http://forums.oracle.com/forums/thread.jspa?threadID=622875
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     04.03.2011  Created
 
  */

  l_file := utl_file.fopen (p_directory_name, p_file_name, g_file_mode_write_byte, max_linesize => 32767 );

  for i in 1 .. ceil (length( p_clob ) / l_chunk_size) loop
    utl_file.put_raw (l_file, utl_raw.cast_to_raw (substr(p_clob, ( i - 1 ) * l_chunk_size + 1, l_chunk_size )));
    utl_file.fflush(l_file);
  end loop; 

  utl_file.fclose (l_file);
  
exception
  when others then
    if utl_file.is_open (l_file) then
      utl_file.fclose (l_file);
    end if;
    raise;  

end save_clob_to_file_raw;  


function file_exists (p_directory_name in varchar2,
                      p_file_name in varchar2) return boolean
as
  l_length      number;
  l_block_size  number; 
  l_returnvalue boolean := false;
begin

  /*
 
  Purpose:      does file exist?
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.01.2011  Created
 
  */

  utl_file.fgetattr (p_directory_name, p_file_name, l_returnvalue, l_length, l_block_size);

  return l_returnvalue;

end file_exists;


function fmt_bytes (p_bytes in number) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      format bytes
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     09.10.2011  Created
 
  */
  
  l_returnvalue := case
                     when p_bytes is null then null
                     when p_bytes < 1024 then to_char(p_bytes) || ' bytes'
                     when p_bytes < 1048576 then to_char(round(p_bytes / 1024, 1)) || ' kB'
                     when p_bytes < 1073741824 then to_char(round(p_bytes / 1048576, 1)) || ' MB'
                     when p_bytes < 1099511627776 then to_char(round(p_bytes / 1073741824, 1)) || ' GB'
                     else to_char(round(p_bytes / 1099511627776, 1)) || ' TB'
                   end;
 
  return l_returnvalue;
 
end fmt_bytes;


end file_util_pkg;
/

