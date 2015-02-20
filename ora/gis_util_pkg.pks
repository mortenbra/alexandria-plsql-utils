create or replace package gis_util_pkg
as
 
  /*
 
  Purpose:      Package contains utility functions related to Geographical Information Systems (GIS)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     06.02.2011  Created
 
  */
 
  g_radius_earth_miles           constant number := 3443.917;
  
  g_latitude_direction_north     constant varchar2(1) := 'N';
  g_latitude_direction_south     constant varchar2(1) := 'S';
  g_longitude_direction_east     constant varchar2(1) := 'E';
  g_longitude_direction_west     constant varchar2(1) := 'W';
  
  -- get ecliptic degree of position
  function get_ecliptic_degree (p_degree in number,
                                p_direction in varchar2) return number;                     
                     
  -- get distance between to geographic position
  function get_ecliptic_distance (p_from_latitude in number,
                                  p_from_longitude in number,
                                  p_to_latitude in number,
                                  p_to_longitude in number,
                                  p_radius in number := g_radius_earth_miles) return number;
 
end gis_util_pkg;
/
