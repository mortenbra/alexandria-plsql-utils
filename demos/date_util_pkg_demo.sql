-- "explode" a specific year/month into one row for each day

select *
from table(date_util_pkg.explode_month(2011, 2))

