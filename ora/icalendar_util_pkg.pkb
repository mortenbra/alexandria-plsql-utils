create or replace package body icalendar_util_pkg
as
 
  /*
 
  Purpose:      Package handles the iCalendar protocol (RFC 5545)
 
  Remarks:      see http://en.wikipedia.org/wiki/ICalendar and http://tools.ietf.org/html/rfc5545
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
 
  */
  
  m_protocol_version             constant varchar2(3) := '2.0';
  m_date_format                  constant varchar2(30) := 'YYYYMMDD"T"HH24MISS';
  m_line_delimiter               constant varchar2(2) := chr(13) || chr(10);

  m_prodid                       varchar2(2000); 


procedure set_prodid (p_prodid in varchar2)
as
begin

  /*
 
  Purpose:      set prodid (company/product name)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.03.2018  Created
 
  */

  m_prodid := substr(p_prodid, 1, 2000);

end set_prodid;


function fmt_date (p_date in date) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin

  /*
 
  Purpose:      format date
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
 
  */
  
  l_returnvalue := to_char(p_date, m_date_format);

  return l_returnvalue;

end fmt_date;


function fmt_organizer (p_organizer_name in varchar2,
                        p_organizer_email in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin

  /*
 
  Purpose:      format date
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
 
  */
  
  l_returnvalue := 'CN="' || p_organizer_name || '":MAILTO:' || p_organizer_email;

  return l_returnvalue;

end fmt_organizer;


function fmt_text (p_text in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin

  /*
 
  Purpose:      format text
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
 
  */
  
  -- TODO: "Actual line feeds in data items are encoded as a backslash followed by the letter N (the bytes 5C 6E or 5C 4E in UTF-8). "

  -- TODO: Encode text according to https://tools.ietf.org/html/rfc5545#section-3.3.11
  
  l_returnvalue := p_text;

  return l_returnvalue;

end fmt_text;


function add_core_object (p_ical_body in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*
 
  Purpose:      wrap core object around iCalendar body
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
 
  */
  
  l_returnvalue := 'BEGIN:VCALENDAR' || m_line_delimiter ||
    'VERSION:' || m_protocol_version || m_line_delimiter ||
    'PRODID:' || nvl(m_prodid, '-//My Company//NONSGML My Product//EN') || m_line_delimiter ||
    p_ical_body || m_line_delimiter ||
    'END:VCALENDAR';

  return l_returnvalue;

end add_core_object;


function get_event_str (p_event in t_event) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      get event string
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
 
  */
  
  l_returnvalue := 'BEGIN:VEVENT' || m_line_delimiter ||
      'SUMMARY:' || fmt_text(p_event.summary) || m_line_delimiter ||
      'DESCRIPTION:' || fmt_text(p_event.description) || m_line_delimiter ||
      'LOCATION:' || fmt_text(p_event.location) || m_line_delimiter ||
      'ORGANIZER;' || fmt_organizer (p_event.organizer_name, p_event.organizer_email) || m_line_delimiter ||
      'DTSTART:' || fmt_date(p_event.start_date) || m_line_delimiter ||
      'DTEND:' || fmt_date(nvl(p_event.end_date, p_event.start_date)) || m_line_delimiter ||
      'DTSTAMP:' || fmt_date(sysdate) || m_line_delimiter ||
      'UID:' || nvl(p_event.uid, rawtohex(sys_guid()) || chr(64) || 'domain.example') || m_line_delimiter ||
      'STATUS:' || nvl(p_event.status, 'CONFIRMED') || m_line_delimiter ||
      'END:VEVENT';
      
  l_returnvalue := add_core_object (l_returnvalue);
 
  return l_returnvalue;
 
end get_event_str;


procedure download_event_str (p_event_str in varchar2,
                              p_filename in varchar2 := null)
as
  l_event_str string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      download event string
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.03.2018  Created
 
  */
  
  owa_util.mime_header('text/calendar', false);
  htp.p('Content-length: ' || length(p_event_str));
  htp.p('Content-Disposition: attachment; filename="' || nvl(p_filename, 'event.ics') || '"');
  owa_util.http_header_close;
  
  htp.prn (p_event_str);
 
end download_event_str;


procedure download_event (p_event in t_event)
as
begin
 
  /*
 
  Purpose:      download event
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
  MBR     07.03.2018  Refactored
 
  */
  
  download_event_str (p_event_str => get_event_str (p_event), p_filename => file_util_pkg.get_filename_str(p_event.summary, 'ics'));
 
end download_event;


function create_event (p_start_date in date,
                       p_end_date in date,
                       p_summary in varchar2,
                       p_description in varchar2 := null,
                       p_location in varchar2 := null,
                       p_organizer_name in varchar2 := null,
                       p_organizer_email in varchar2 := null,
                       p_status in varchar2 := null,
                       p_uid in varchar2 := null) return t_event
as
  l_returnvalue t_event;
begin
 
  /*
 
  Purpose:      create event
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
 
  */
  
  l_returnvalue.start_date := p_start_date;
  l_returnvalue.end_date := p_end_date;
  l_returnvalue.summary := p_summary;
  l_returnvalue.description := p_description;
  l_returnvalue.location := p_location;
  l_returnvalue.organizer_name := p_organizer_name;
  l_returnvalue.organizer_email := p_organizer_email;
  l_returnvalue.status := p_status;
  l_returnvalue.uid := p_uid;
 
  return l_returnvalue;
 
end create_event;

 
end icalendar_util_pkg;
/
 


