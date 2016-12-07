-- "explode" a specific year/month into one row for each day

select *
from table(date_util_pkg.explode_month(2011, 2))

-- generate a table of dates based on a "calendar string"
-- for calendar string syntax, see http://docs.oracle.com/cd/B28359_01/appdev.111/b28419/d_sched.htm#i1009923
-- a start and stop date can be specified, it not specified it defaults to a year from now

select t.column_value
from table(date_util_pkg.get_date_tab('FREQ=WEEKLY; BYDAY=MON,WED,FRI', trunc(sysdate), trunc(sysdate+90))) t