create or replace package file_util_pkg
as

  /*
 
  Purpose:      Package contains file utilities 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2005  Created
  MBR     18.01.2011  Added blob/clob operations
 
  */

  -- operating system types
  g_os_windows                   constant varchar2(1) := 'w';
  g_os_unix                      constant varchar2(1) := 'u';
  
  g_dir_sep_win                  constant varchar2(1) := '\';
  g_dir_sep_unix                 constant varchar2(1) := '/';
  
  g_file_ext_sep                 constant varchar2(1) := '.';
  
  -- file open modes
  g_file_mode_append_text        constant varchar2(1) := 'a';
  g_file_mode_append_byte        constant varchar2(2) := 'ab';
  g_file_mode_read_text          constant varchar2(1) := 'r';
  g_file_mode_read_byte          constant varchar2(2) := 'rb';
  g_file_mode_write_text         constant varchar2(1) := 'w';
  g_file_mode_write_byte         constant varchar2(2) := 'wb';
  
  g_file_name_def                varchar2(2000);
  subtype t_file_name is g_file_name_def%type;

  g_file_ext_def                 varchar2(50);
  subtype t_file_ext is g_file_ext_def%type;

  g_dir_sep_def                  varchar2(1);
  subtype t_dir_sep is g_dir_sep_def%type;
  
  -- resolve filename
  function resolve_filename (p_dir in varchar2,
                             p_file_name in varchar2,
                             p_os in varchar2 := g_os_windows) return varchar2;
                             
  -- extract filename
  function extract_filename (p_file_name in varchar2,
                             p_os in varchar2 := g_os_windows) return varchar2;
                         
  -- get file extension    
  function get_file_ext (p_file_name in varchar2) return varchar2;
  
  -- strip file extension
  function strip_file_ext (p_file_name in varchar2) return varchar2;
                             
  -- get filename string (no whitespace)
  function get_filename_str (p_str in varchar2,
                             p_extension in varchar2 := null) return varchar2;

  -- get blob from file
  function get_blob_from_file (p_directory_name in varchar2,
                               p_file_name in varchar2) return blob;

  -- get clob from file
  function get_clob_from_file (p_directory_name in varchar2,
                               p_file_name in varchar2) return clob;

  -- save blob to file
  procedure save_blob_to_file (p_directory_name in varchar2,
                               p_file_name in varchar2,
                               p_blob in blob);  

  -- save clob to file
  procedure save_clob_to_file (p_directory_name in varchar2,
                               p_file_name in varchar2,
                               p_clob in clob);  

  -- save clob to file (raw)
  procedure save_clob_to_file_raw (p_directory_name in varchar2,
                                   p_file_name in varchar2,
                                   p_clob in clob);  
                               
  -- does file exist?
  function file_exists (p_directory_name in varchar2,
                        p_file_name in varchar2) return boolean;
  
  -- format bytes
  function fmt_bytes (p_bytes in number) return varchar2;

end file_util_pkg;
/

