CREATE OR REPLACE package body date_util_pkg
as

  /*

  Purpose:    Package handles functionality related to date and time

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  

function get_year (p_date in date) return number
as
  l_returnvalue number;
begin

  /*

  Purpose:    return year based on date

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */

  l_returnvalue:=to_number(to_char(p_date, 'YYYY'));
  
  return l_returnvalue;
  
end get_year;
  

function get_month (p_date in date) return number
as
  l_returnvalue number;
begin

  /*

  Purpose:    return month based on date

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */

  l_returnvalue:=to_number(to_char(p_date, 'MM'));
  
  return l_returnvalue;

end get_month;


function get_start_date_year (p_date in date) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    return start date of year based on date

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=to_date('01.01.' || to_char(get_year(p_date)), 'DD.MM.YYYY');
  
  return l_returnvalue;

end get_start_date_year;

  
function get_start_date_year (p_year in number) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    return start date of year

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=to_date('01.01.' || to_char(p_year), 'DD.MM.YYYY');

  return l_returnvalue;

end get_start_date_year;


function get_end_date_year (p_date in date) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    return end date of year based on date

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=to_date('31.12.' || to_char(get_year(p_date)), 'DD.MM.YYYY');
  
  return l_returnvalue;

end get_end_date_year;

  
function get_end_date_year (p_year in number) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    return end date of year

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=to_date('31.12.' || to_char(p_year), 'DD.MM.YYYY');

  return l_returnvalue;

end get_end_date_year;


function get_start_date_month (p_date in date) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    return start date of month based on date

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=to_date('01.' || to_char(lpad(get_month(p_date),2,'0')) || '.' || to_char(get_year(p_date)), 'DD.MM.YYYY');

  return l_returnvalue;

end get_start_date_month;

  
function get_start_date_month (p_year in number,
                               p_month in number) return date  
as
  l_returnvalue date;
begin

  /*

  Purpose:    return start date of month

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=to_date('01.' || to_char(lpad(p_month,2,'0')) || '.' || to_char(p_year), 'DD.MM.YYYY');

  return l_returnvalue;

end get_start_date_month;

                                
function get_end_date_month (p_date in date) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    return end date of month based on date

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=last_day(trunc(p_date));

  return l_returnvalue;

end get_end_date_month;

  
function get_end_date_month (p_year in number,
                             p_month in number) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    return end date of month

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=last_day(trunc(get_start_date_month(p_year, p_month)));
  
  return l_returnvalue;

end get_end_date_month;


function get_days_in_month (p_year in number,
                            p_month in number) return number
as
  l_returnvalue number;
begin

  /*

  Purpose:    return number of days in given month

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  l_returnvalue:=get_end_date_month(p_year, p_month) - get_start_date_month(p_year, p_month) + 1;
  
  return l_returnvalue;

end get_days_in_month;

  
function get_days_in_period (p_from_date_1 in date,
                             p_to_date_1 in date,
                             p_from_date_2 in date,
                             p_to_date_2 in date) return number
as
  l_returnvalue number;
  l_begin_date date;
  l_end_date date;
begin

  /*

  Purpose:    return number of days in one period that fall within another period

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  if p_to_date_2 > p_from_date_1 then

    if p_from_date_1 < p_from_date_2 then
      l_begin_date := p_from_date_2;
    else
      l_begin_date := p_from_date_1;
    end if;

    if p_to_date_1 > p_to_date_2 then
      l_end_date := p_to_date_2;
    else
      l_end_date := p_to_date_1;
    end if;

    l_returnvalue := l_end_date - l_begin_date;

  else
    l_returnvalue := 0;
  end if;

  if l_returnvalue < 0 then
    l_returnvalue := 0;
  end if;
  
  return l_returnvalue;

end get_days_in_period;


function is_period_in_range (p_year in number,
                             p_month in number,
                             p_from_year in number,
                             p_from_month in number,
                             p_to_year in number,
                             p_to_month in number) return boolean
as
  l_returnvalue boolean := false;
  
  l_date        date;
  l_start_date  date;
  l_end_date    date;
  
begin

  /*

  Purpose:    returns true if period falls within range

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     26.09.2006  Created

  */

--  if (p_year between p_from_year and p_to_year) then
--    if (p_year < p_to_year) or (p_year = p_to_year and p_month <= p_to_month) or (p_year = p_from_year and p_month >= p_from_month) then
--      l_returnvalue:=true;
--    end if;
--  end if;

  l_date:=get_start_date_month(p_year, p_month);
  l_start_date:=get_start_date_month (p_from_year, p_from_month);
  l_end_date:=get_end_date_month (p_to_year, p_to_month);
  
  if l_date between l_start_date and l_end_date then
    l_returnvalue:=true;
  end if;
  
  return l_returnvalue;

end is_period_in_range;


function get_quarter (p_month in number) return number
as
  l_returnvalue number;
begin

  /*

  Purpose:    get quarter based on month

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     24.11.2006  Created

  */

  if p_month in (1,2,3) then
    l_returnvalue:=1;
  elsif p_month in (4,5,6) then
    l_returnvalue:=2;
  elsif p_month in (7,8,9) then
    l_returnvalue:=3;
  elsif p_month in (10,11,12) then
    l_returnvalue:=4;
  end if;
  
  return l_returnvalue;

end get_quarter;


function fmt_time (p_days in number) return varchar2
as
  l_days            number;
  l_hours           number;
  l_minutes         number;
  l_seconds         number;
  l_sign            varchar2(6);
  l_returnvalue     string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:    get time formatted as days, hours, minutes, seconds

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     18.12.2006  Created
  MBR     19.01.2012  Fixed: Sometimes incorrect results due to rounding minutes
  MBR     02.09.2012  Improved formatting
  MBR     11.11.2012  Removed seconds from display of "X hours, Y minutes"

  */
  
  l_days := nvl(trunc(p_days),0);
  l_hours := nvl(((p_days - l_days) * 24), 0);
  l_minutes := nvl(((l_hours - trunc(l_hours))) * 60, 0);
  l_seconds := nvl(((l_minutes - trunc(l_minutes))) * 60, 0);

  if p_days < 0 then
    l_sign:='minus ';
  else
    l_sign:='';
  end if;

  l_days:=abs(l_days);
  l_hours:=trunc(abs(l_hours));
  --l_minutes:=round(abs(l_minutes));
  l_minutes:=trunc(abs(l_minutes));
  l_seconds:=round(abs(l_seconds));

  if l_minutes = 60 then
    l_hours:=l_hours + 1;
    l_minutes:=0;
  end if;
  
  if (l_days > 0) and (l_hours = 0) then
    l_returnvalue:=string_util_pkg.get_str('%1 days', l_days);
  elsif (l_days > 0) then
    l_returnvalue:=string_util_pkg.get_str('%1 days, %2 hours, %3 minutes', l_days, l_hours, l_minutes);
  elsif (l_hours > 0) and (l_minutes = 0) then
    l_returnvalue:=string_util_pkg.get_str('%1 hours', l_hours);
  elsif (l_hours > 0) then
    l_returnvalue:=string_util_pkg.get_str('%1 hours, %2 minutes', l_hours, l_minutes);
  elsif (l_minutes > 0) and (l_seconds = 0) then
    l_returnvalue:=string_util_pkg.get_str('%1 minutes', l_minutes);
  elsif (l_minutes > 0) then
    l_returnvalue:=string_util_pkg.get_str('%1 minutes, %2 seconds', l_minutes, l_seconds);
  else
    l_returnvalue:=string_util_pkg.get_str('%1 seconds', l_seconds);
  end if;
  
  l_returnvalue:=l_sign || l_returnvalue;
  
  return l_returnvalue;

end fmt_time;
  

function fmt_time (p_from_date in date,
                   p_to_date in date) return varchar2
as
begin

  /*

  Purpose:    get time between two dates formatted as days, hours, minutes, seconds

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     18.12.2006  Created

  */

  return fmt_time (p_to_date - p_from_date);

end fmt_time;


function fmt_date (p_date in date) return varchar2
as
  l_returnvalue     string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:    format date as date

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     06.10.2010  Created

  */
  
  l_returnvalue := to_char(p_date, g_date_fmt_date);

  return l_returnvalue;
  
end fmt_date;


function fmt_datetime (p_date in date) return varchar2
as
  l_returnvalue     string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:    format date as datetime

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     15.04.2010  Created
  MBR     06.10.2010  Use date format defined in appl_pkg

  */
  
  l_returnvalue := to_char(p_date, g_date_fmt_date_hour_min);

  return l_returnvalue;
  
end fmt_datetime;


function get_days_in_year (p_year in number) return number
as
  l_returnvalue number;
begin
  
  /*

  Purpose:    get number of days in year

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     21.04.2010  Created

  */  
  
  l_returnvalue := get_start_date_month ((p_year + 1), 1) - get_start_date_month (p_year, 1);

  return l_returnvalue;
  
end get_days_in_year;


function explode_month (p_year in number,
                        p_month in number) return t_period_date_tab pipelined
as
  l_date        date;
  l_start_date  date;
  l_end_date    date;
  l_day         pls_integer := 0;
  l_returnvalue t_period_date;
begin
 
  /*
 
  Purpose:      returns collection of dates in specified month
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     30.06.2010  Created
 
  */
  
  l_returnvalue.year := p_year; 
  l_returnvalue.month := p_month; 

  l_start_date := get_start_date_month (p_year, p_month);
  l_end_date := get_end_date_month (p_year, p_month);

  l_returnvalue.days_in_month := l_end_date - l_start_date + 1; 
  
  l_date := l_start_date;
 
  loop
  
    l_day := l_day + 1;
    l_returnvalue.day := l_day;
    l_returnvalue.the_date := l_date;

    pipe row (l_returnvalue);

    if l_date >= l_end_date then
      exit;
    end if; 

    l_date := l_date + 1;

  end loop;

  return;
 
end explode_month;


function get_date_tab (p_calendar_string in varchar2,
                       p_from_date in date := null,
                       p_to_date in date := null) return t_date_array pipelined
as
  l_from_date                    date := coalesce(p_from_date, sysdate);
  l_to_date                      date := coalesce(p_to_date, add_months(l_from_date,12));
  l_date_after                   date;
  l_next_date                    date;
begin

  /*
 
  Purpose:      get table of dates based on specified calendar string
 
  Remarks:      see https://oraclesponge.wordpress.com/2010/08/18/generating-lists-of-dates-in-oracle-the-dbms_scheduler-way/
                see http://www.kibeha.dk/2014/12/date-row-generator-with-dbmsscheduler.html
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.09.2015  Created
 
  */

  l_date_after := l_from_date - 1;

  loop

    dbms_scheduler.evaluate_calendar_string (
      calendar_string   => p_calendar_string,
      start_date        => l_from_date,
      return_date_after => l_date_after,
      next_run_date     => l_next_date
    );

    exit when l_next_date > l_to_date;

    pipe row (l_next_date);
    
    l_date_after := l_next_date;

  end loop;

  return;

end get_date_tab;

end date_util_pkg;
/
