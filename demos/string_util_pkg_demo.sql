-- replace several strings at once (useful for processing text templates such as emails or web pages)

select string_util_pkg.multi_replace ('this is my #COLOR# string (not only #COLOR# but also #SIZE#)', t_str_array('#COLOR#', '#SIZE#'), t_str_array('green', 'great'))
from dual

-- split string into rows

select *
from table(string_util_pkg.split_str ('CLOSED,IN PROGRESS,REJECTED', ','))

-- useful for variable IN clauses

select *
from emp
where ename in (select column_value
                from table(string_util_pkg.split_str ('SMITH,ADAMS,JAMES', ',')))


-- join together many rows into one string (SQL query)

select string_util_pkg.join_str(cursor(select ename from emp order by ename))
from dual

-- join together many rows into one string (PL/SQL)

declare
  l_val varchar2(32000);
  l_cursor sys_refcursor;
begin
  open l_cursor for select ename from emp order by ename;
  l_val := string_util_pkg.join_str(l_cursor);
  dbms_output.put_line(l_val);
end;


-- randomize array of strings

declare
  l_test1 t_str_array ('one', 'two', 'three', 'four');
begin

  debug_pkg.debug_on;

  for i in l_test1.first .. l_test1.last loop
    debug_pkg.printf('%1 = %2', i, l_test1(i));
  end loop;

  l_test1 := randomize_array (l_test1);

  for i in l_test1.first .. l_test1.last loop
    debug_pkg.printf('%1 = %2', i, l_test1(i));
  end loop;

end;


