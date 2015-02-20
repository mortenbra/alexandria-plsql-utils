create or replace package body sys.utl_file_nonstandard
as

  /*

  Purpose:    Package contains functionality missing from the standard UTL_FILE package

  Remarks:    This package MUST be created in the SYS schema due to a dependency on an X$ table
              See http://www.chrispoole.co.uk/tips/plsqltip2.htm

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.07.2011  Created
  
  */


function get_file_list (p_directory_name in varchar2,
                        p_file_pattern in varchar2 := null,
                        p_max_files in number := null) return t_file_list
as
  l_user                 dba_tab_privs.grantee%type := user;
  l_directory_name       dba_directories.directory_name%type := upper(p_directory_name);
  l_directory_path       dba_directories.directory_path%type;
  l_pattern              varchar2(2000);
  l_dummy                varchar2(2000) := null;
  l_dir_sep              varchar2(1) := null;
  l_returnvalue          t_file_list;

  e_bug_data_conv        exception; 
  pragma exception_init  (e_bug_data_conv, -6502);

begin

  /*

  Purpose:    get list of files in directory

  Remarks:    This package MUST be created in the SYS schema due to a dependence on an X$ table
              See http://www.chrispoole.co.uk/tips/plsqltip2.htm

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.07.2011  Created
  MBR     16.08.2011  Workaround for ORA-06502, see http://forums.oracle.com/forums/thread.jspa?threadID=662413
  
  */

  begin
    select table_name
    into l_directory_name
    from dba_tab_privs
    where table_name = l_directory_name
    and grantee = l_user
    and privilege = 'READ'
    and rownum = 1;
  exception
    when no_data_found then
      raise_application_error (-20000, 'User ' || l_user || ' does not have READ privilege on directory ' || l_directory_name);
  end;

  begin
    select directory_path
    into l_directory_path
    from dba_directories
    where directory_name = l_directory_name;
  exception
    when no_data_found then
      raise_application_error (-20000, 'Directory ' || l_directory_name || ' not found');
  end;

  -- Unix or Windows system?

  if instr(l_directory_path, '/') > 0 then
    l_dir_sep := '/';
  else
    l_dir_sep := '\';
  end if;

  -- make sure the path has a trailing directory separator

  if instr(l_directory_path, l_dir_sep, length(l_directory_path)) = 0 then
    l_directory_path := l_directory_path || l_dir_sep;
  end if;

  if p_file_pattern is not null then
    l_pattern := l_directory_path || '\' || p_file_pattern;
  else
    l_pattern := l_directory_path;
  end if;

  begin
    dbms_backup_restore.searchfiles (l_pattern, ns => l_dummy);
  exception
    when e_bug_data_conv then
      -- workaround: just try again
      dbms_backup_restore.searchfiles (l_pattern, ns => l_dummy);
  end;

  select fname_krbmsft as file_name
  bulk collect into l_returnvalue
  from x$krbmsft
  order by 1;

  return l_returnvalue;

end get_file_list;


end utl_file_nonstandard;
/

