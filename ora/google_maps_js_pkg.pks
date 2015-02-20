create or replace package google_maps_js_pkg
as
 
  /*
 
  Purpose:      Package handles Google Maps integration with JavaScript
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.02.2011  Created
 
  */
  
  type t_map_options is record (
    map_control_enabled boolean,
    map_type_control_enabled boolean
  );
 
 
  -- initialize map
  procedure init_map (p_map_id in varchar2,
                      p_options in t_map_options := null);
 
  -- add point to map
  procedure add_point (p_point in google_maps_pkg.t_point);
 
  -- render map script
  procedure render_map_script;
 
  -- render map placeholder
  procedure render_map_placeholder (p_style in varchar2 := null,
                                    p_attributes in varchar2 := null);
 
end google_maps_js_pkg;
/

