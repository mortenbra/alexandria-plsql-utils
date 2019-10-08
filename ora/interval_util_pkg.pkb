CREATE OR REPLACE package body interval_util_pkg
as

  /*

  Purpose:    Package handles functionality related to intervals

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  AJM     14.09.2015  Created

  */


function dsintervaltonum (p_interval in interval day to second, p_unit in varchar2) return number deterministic is
  l_illegal_argument exception;
  pragma exception_init (l_illegal_argument, -1760);
  l_returnvalue number;
begin

  /*

  Purpose:    convert an interval day to second to number

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  AJM     14.09.2015  Created

  */

  case upper (p_unit)
    when 'SECOND'
    then
      l_returnvalue :=
	    extract (day from p_interval) * 86400
      + extract (hour from p_interval) * 3600
      + extract (minute from p_interval) * 60
      + extract (second from p_interval);
    when 'MINUTE'
    then
      l_returnvalue :=
	      extract (day from p_interval) * 1440
        + extract (hour from p_interval) * 60
        + extract (minute from p_interval)
        + extract (second from p_interval) / 60;
    when 'HOUR'
    then
      l_returnvalue :=
	      extract (day from p_interval) * 24
        + extract (hour from p_interval)
        + extract (minute from p_interval) / 60
        + extract (second from p_interval) / 3600;
    when 'DAY'
    then
      l_returnvalue :=
	      extract (day from p_interval)
        + extract (hour from p_interval) / 24
        + extract (minute from p_interval) / 1440
        + extract (second from p_interval) / 86400;
    else
      raise l_illegal_argument;
  end case;

  return l_returnvalue;

end dsintervaltonum;


function ymintervaltonum (p_interval in interval year to month, p_unit in varchar2) return number deterministic is
  l_illegal_argument exception;
  pragma exception_init (l_illegal_argument, -1760);
  l_returnvalue number;
begin

  /*

  Purpose:    convert an interval year to month to number

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  AJM     14.09.2015  Created

  */

  case upper (p_unit)
    when 'MONTH'
    then
      l_returnvalue :=
	      extract (month from p_interval)
        + extract (year from p_interval) * 12;
    when 'YEAR'
    then
      l_returnvalue :=
	      extract (month from p_interval) / 12
        + extract (year from p_interval);
    else
      raise l_illegal_argument;
  end case;

  return l_returnvalue;

end ymintervaltonum;


end interval_util_pkg;
/
