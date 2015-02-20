create or replace package google_maps_pkg
as

  /*
 
  Purpose:      Package handles Google Maps integration  
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     01.01.2008  Created
 
  */
  
  g_map_type_normal              constant varchar2(30) := 'G_NORMAL_MAP';
  g_map_type_satellite           constant varchar2(30) := 'G_SATELLITE_MAP';
  g_map_type_hybrid              constant varchar2(30) := 'G_HYBRID_MAP';
  g_map_type_physical            constant varchar2(30) := 'G_PHYSICAL_MAP';
  
  type t_point is record (
    longitude number,
    latitude number,
    name varchar2(255),
    info varchar2(2000)
  );
  
  type t_point_list is table of t_point index by binary_integer;

  -- set API key
  procedure set_api_key (p_api_key in varchar2);
 
  -- get API key
  function get_api_key return varchar2;

  -- get geocode from address
  function get_geocode (p_address in varchar2) return sdo_geometry;

  -- get point from geocode
  function get_point (p_geocode in sdo_geometry,
                      p_name in varchar2 := null) return t_point;

  -- get point from address
  function get_point (p_address in varchar2) return t_point;

  -- get point from degree
  function get_point (p_longitude in number,
                      p_longitude_direction in varchar2,
                      p_latitude in number,
                      p_latitude_direction in varchar2,
                      p_name in varchar2 := null) return t_point; 

  -- get geocode and print it
  procedure debug_geocode (p_address in varchar2);

end google_maps_pkg;
/

