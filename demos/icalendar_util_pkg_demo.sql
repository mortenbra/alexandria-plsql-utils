-- get iCalendar event

declare
  l_event_str varchar2(32000);
begin
  debug_pkg.debug_on;
  l_event_str := icalendar_util_pkg.get_event (icalendar_util_pkg.create_event (p_start_date => sysdate, p_end_date => sysdate + 2, p_summary => 'PAARTY!!!'));
  debug_pkg.printf('l_event_str = %1', chr(10) || l_event_str); 
end;

