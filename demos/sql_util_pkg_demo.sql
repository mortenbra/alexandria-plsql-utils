

-- make a number of rows

select *
from table(sql_util_pkg.make_rows (10))

-- make rows in specified range

select *
from table(sql_util_pkg.make_rows (10, 13))

