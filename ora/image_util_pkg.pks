create or replace package image_util_pkg
as
 
  /*
 
  Purpose:      Package handles images
 
  Remarks:      Based on image parsing code from Anton Scheffer's AS_PDF3 package
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */
  
  g_format_jpg                   constant varchar2(3) := 'jpg';
  g_format_png                   constant varchar2(3) := 'png';
  g_format_gif                   constant varchar2(3) := 'gif';

 
  type t_image_info is record (
    adler32            varchar2(8),
    width              pls_integer,
    height             pls_integer,
    color_res          pls_integer,
    color_tab          raw(768),
    greyscale          boolean,
    pixels             blob,
    type               varchar2(5),
    nr_colors          pls_integer,
    transparency_index pls_integer
  );
 
  -- returns true if blob is image
  function is_image (p_file in blob,
                     p_format in varchar2 := null) return boolean;
 
  -- get image information
  function get_image_info (p_file in blob) return t_image_info;
 
 
end image_util_pkg;
/

