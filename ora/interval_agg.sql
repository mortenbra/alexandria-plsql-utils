/*

Purpose:    Interval aggregate functions

Remarks:    

Who     Date        Description
------  ----------  -------------------------------------
AJM     14.09.2015  Created

*/

-- sum aggregate function for interval day to second
create or replace function sum_dsinterval (x dsinterval_unconstrained) return dsinterval_unconstrained
parallel_enable
aggregate using t_sum_dsinterval;
/

-- average aggregate function for interval day to second
create or replace function avg_dsinterval (x dsinterval_unconstrained) return dsinterval_unconstrained
parallel_enable
aggregate using t_avg_dsinterval;
/

-- sum aggregate function for interval year to month
create or replace function sum_yminterval (x yminterval_unconstrained) return yminterval_unconstrained
parallel_enable
aggregate using t_sum_yminterval;
/

-- average aggregate function for interval year to month
create or replace function avg_yminterval (x yminterval_unconstrained) return yminterval_unconstrained
parallel_enable
aggregate using t_avg_yminterval;
/
