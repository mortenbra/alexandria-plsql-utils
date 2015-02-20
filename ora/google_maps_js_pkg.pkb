create or replace package body google_maps_js_pkg
as
 
  /*
 
  Purpose:      Package handles Google Maps integration with JavaScript
 
  Remarks:      see http://code.google.com/apis/maps/documentation/javascript/v2/reference.html
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.02.2011  Created
 
  */
  
  g_map_id                       varchar2(255);
  g_map_options                  t_map_options;
  g_point_list                   google_maps_pkg.t_point_list;
 
 
procedure init_map (p_map_id in varchar2,
                    p_options in t_map_options := null) 
as
begin
 
  /*
 
  Purpose:      initialize map
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.02.2011  Created
 
  */
 
  g_map_id := p_map_id;
  g_map_options := p_options;
  g_point_list.delete;
 
end init_map;
 
 
procedure add_point (p_point in google_maps_pkg.t_point) 
as
begin
 
  /*
 
  Purpose:      add point to map
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.02.2011  Created
 
  */
  
  if g_point_list.count = 0 then
    g_point_list(1) := p_point;
  else
    g_point_list(g_point_list.last+1) := p_point;
  end if;
 
 
end add_point;


procedure render_map_script
as
  l_str string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      render map script
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.02.2011  Created
 
  */
 
  
  htp.p('<script src="http://maps.google.com/maps?file=api&v=2&key=' || google_maps_pkg.get_api_key || '" type="text/javascript"></script> 
<script type="text/javascript">
//<![CDATA[   
//globals 
var bounds = new GLatLngBounds(); 
function initMap() { 
if (GBrowserIsCompatible()) {    
  var map = new GMap2(document.getElementById("' || g_map_id || '")); 
  map.setUIToDefault();');
  
  
  for i in 1 .. g_point_list.count loop
  
    l_str := string_util_pkg.get_str('var point = new GLatLng(%2, %3); 
  bounds.extend(point); 
  map.setCenter(point); 
  map.setZoom(map.getBoundsZoomLevel(bounds)-1); 
  var markerOption%1 = { title: "%4"};
  var marker%1 = new GMarker(point, markerOption%1); 
  map.addOverlay(marker%1);', i, g_point_list(i).latitude, g_point_list(i).longitude, g_point_list(i).name);
  
    htp.p(l_str);

    if g_point_list(i).info is not null then
      --l_str := string_util_pkg.get_str('GEvent.addListener(marker%1, "click", function() { marker%1.openInfoWindowHtml("%2"); } );', i, replace(g_point_list(i).info, '"', ''''));
      --htp.p(l_str);
      owa_util_pkg.htp_printf('GEvent.addListener(marker%1, "click", function() { marker%1.openInfoWindowHtml("%2"); } );', i, replace(g_point_list(i).info, '"', ''''));
    end if;
  
  end loop;
  
  htp.p('
   }
   }
   //]]>
</script>');


end render_map_script;


procedure render_map_placeholder (p_style in varchar2 := null,
                                  p_attributes in varchar2 := null)
as
  l_str string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      render map placeholder
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.02.2011  Created
 
  */
 
  htp.p('<div id="' || g_map_id || '" style="' || nvl(p_style, 'width: 800px; height: 600px') || '" ' || p_attributes || '></div>');

end render_map_placeholder;

 
end google_maps_js_pkg;
/
 

