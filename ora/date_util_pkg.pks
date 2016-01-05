CREATE OR REPLACE package date_util_pkg
as

  /*

  Purpose:    Package handles functionality related to date and time

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.09.2006  Created

  */
  
  g_date_fmt_date                constant varchar2(30) := 'dd.mm.yyyy';
  g_date_fmt_date_hour_min       constant varchar2(30) := 'dd.mm.yyyy hh24:mi';
  g_date_fmt_date_hour_min_sec   constant varchar2(30) := 'dd.mm.yyyy hh24:mi:ss';

  g_months_in_quarter            constant number := 3;
  g_months_in_year               constant number := 12;

  type t_period_date is record (
    year           number,
    month          number,
    day            number,
    days_in_month  number,
    the_date       date
  );
  
  type t_period_date_tab is table of t_period_date;

  -- return year based on date
  function get_year (p_date in date) return number;
  
  -- return month based on date
  function get_month (p_date in date) return number;
  
  -- return start date of year based on date
  function get_start_date_year (p_date in date) return date;
  
  -- return start date of year
  function get_start_date_year (p_year in number) return date;

  -- return end date of year based on date
  function get_end_date_year (p_date in date) return date;
  
  -- return end date of year
  function get_end_date_year (p_year in number) return date;

  -- return start date of month based on date
  function get_start_date_month (p_date in date) return date;
  
  -- return start date of month
  function get_start_date_month (p_year in number,
                                 p_month in number) return date;  
                                
  -- return end date of month based on date
  function get_end_date_month (p_date in date) return date;
  
  -- return end date of month
  function get_end_date_month (p_year in number,
                               p_month in number) return date;

  -- return number of days in given month
  function get_days_in_month (p_year in number,
                              p_month in number) return number;

  -- return number of days in one period that fall within another period
  function get_days_in_period (p_from_date_1 in date,
                               p_to_date_1 in date,
                               p_from_date_2 in date,
                               p_to_date_2 in date) return number;

  -- returns true if period falls within range
  function is_period_in_range (p_year in number,
                               p_month in number,
                               p_from_year in number,
                               p_from_month in number,
                               p_to_year in number,
                               p_to_month in number) return boolean;
                               
  -- get quarter based on month
  function get_quarter (p_month in number) return number;
  
  -- get time formatted as days, hours, minutes, seconds
  function fmt_time (p_days in number) return varchar2;
  
  -- get time between two dates formatted as days, hours, minutes, seconds
  function fmt_time (p_from_date in date,
                     p_to_date in date) return varchar2;
                     
  -- get date formatted as date
  function fmt_date (p_date in date) return varchar2;

  -- get date formatted as date and time
  function fmt_datetime (p_date in date) return varchar2;
  
  -- get number of days in year
  function get_days_in_year (p_year in number) return number;

  -- returns collection of dates in specified month
  function explode_month (p_year in number,
                          p_month in number) return t_period_date_tab pipelined;

  -- get table of dates based on specified calendar string
  function get_date_tab (p_calendar_string in varchar2,
                         p_from_date in date := null,
                         p_to_date in date := null) return t_date_array pipelined;

end date_util_pkg;
/
