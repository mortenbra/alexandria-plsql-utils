-- get list of files in specified directory

declare
  l_file_list sys.utl_file_nonstandard.t_file_list;
begin
  debug_pkg.debug_on;
  l_file_list := sys.utl_file_nonstandard.get_file_list('DEVTEST_TEMP_DIR', '*.xls');
  for i in 1 .. l_file_list.count loop
    debug_pkg.printf('File %1, file name = %2', i, l_file_list(i));
  end loop;
end;


