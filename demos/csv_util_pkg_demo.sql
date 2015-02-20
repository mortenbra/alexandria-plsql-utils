-- retrieve a download a CSV file as a clob directly from the web and return it as a table with a single statement:

select *
from table(csv_util_pkg.clob_to_csv(httpuritype('http://www.foo.example/bar.csv').getclob()))

-- do a direct insert via INSERT .. SELECT

insert into my_table (first_column, second_column)
select c001, c002
from table(csv_util_pkg.clob_to_csv(httpuritype('http://www.foo.example/bar.csv').getclob()))


-- use SQL to filter the results (although this may affect performance)

select *
from table(csv_util_pkg.clob_to_csv(httpuritype('http://www.foo.example/bar.csv').getclob()))
where c002 = 'Chevy'


-- do it in a more procedural fashion

create table x_dump
(clob_value clob,
 dump_date date default sysdate,
 dump_id number);


declare
  l_clob clob;

  cursor l_cursor
  is
  select csv.*
  from x_dump d, table(csv_util_pkg.clob_to_csv(d.clob_value)) csv
  where d.dump_id = 1;

begin

  l_clob := httpuritype('http://www.foo.example/bar.csv').getclob();
  insert into x_dump (clob_value, dump_id) values (l_clob, 1);
  commit;
  dbms_lob.freetemporary (l_clob);

  for l_rec in l_cursor loop
    dbms_output.put_line ('row ' || l_rec.line_number || ', col 1 = ' || l_rec.c001);
  end loop;

end;

/*

There are a few additional functions in the package that are not necessary for normal usage,
but may be useful if you are doing any sort of lower-level CSV parsing.

The csv_to_array function operates on a single CSV-encoded line
(so to use this you would have to split the CSV lines yourself first,
and feed them one by one to this function):

*/

declare
  l_array t_str_array;
  l_val varchar2(4000);
begin

  l_array := csv_util_pkg.csv_to_array ('10,SMITH,CLERK,"1200,50"');

  for i in l_array.first .. l_array.last loop
    dbms_output.put_line('value ' || i || ' = ' || l_array(i));
  end loop;

  -- should output SMITH
  l_val := csv_util_pkg.get_array_value(l_array, 2);
  dbms_output.put_line('value = ' || l_val);

  -- should give an error message stating that there is no column called DEPTNO because the array does not contain seven elements
  -- leave the column name out to fail silently and return NULL instead of raising exception
  l_val := csv_util_pkg.get_array_value(l_array, 7, 'DEPTNO');
  dbms_output.put_line('value = ' || l_val);

end;


-- You can also use this package to export CSV data, for example by using a query like this.

select csv_util_pkg.array_to_csv (t_str_array(company_id, company_name, company_type)) as the_csv_data
from company
order by company_name

/*

THE_CSV_DATA
--------------------------------
260,Acorn Oil & Gas,EXT
261,Altinex,EXT
262,Amerada Hess,EXT
263,Atlantic Petroleum,EXT
264,Beryl,EXT
265,BG,EXT
266,Bow Valley Energy,EXT
267,BP,EXT

*/

