-- generate a clob and save it to file

declare
  l_clob clob;
begin

  l_clob := '<html><body>';
  for l_rec in (select * from emp) loop
    l_clob := l_clob || '<li>' || l_rec.ename || '</li>';
  end loop;
  l_clob := l_clob || '</body></html>';

  file_util_pkg.save_clob_to_file ('DEVTEST_TEMP_DIR', 'my_generated_web_page.html', l_clob);

end;

