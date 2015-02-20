create or replace package icalendar_util_pkg
as
 
  /*
 
  Purpose:      Package handles the iCalendar protocol (RFC 5545)
 
  Remarks:      see http://en.wikipedia.org/wiki/ICalendar and http://tools.ietf.org/html/rfc5545
  
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.10.2012  Created
 
  */
  
  type t_event is record (
    start_date      date,
    end_date        date,
    summary         varchar2(2000),
    description     varchar2(2000),
    location        varchar2(2000),
    organizer_name  varchar2(2000),
    organizer_email varchar2(2000),
    uid             varchar2(2000)
  );
 
 
  -- get event
  function get_event (p_event in t_event) return varchar2;
 
  -- download event
  procedure download_event (p_event in t_event);

  -- create event
  function create_event (p_start_date in date,
                         p_end_date in date,
                         p_summary in varchar2,
                         p_description in varchar2 := null,
                         p_location in varchar2 := null,
                         p_organizer_name in varchar2 := null,
                         p_organizer_email in varchar2 := null,
                         p_uid in varchar2 := null) return t_event;
 
end icalendar_util_pkg;
/

