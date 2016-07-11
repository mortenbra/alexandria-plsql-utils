CREATE OR REPLACE package interval_util_pkg
as

  /*

  Purpose:    Package handles functionality related to intervals

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  AJM     14.09.2015  Created

  */

  -- convert an interval day to second to number
  function dsintervaltonum (p_interval in interval day to second, p_unit in varchar2) return number deterministic;

  -- convert an interval year to month to number
  function ymintervaltonum (p_interval in interval year to month, p_unit in varchar2) return number deterministic;

end interval_util_pkg;
/
