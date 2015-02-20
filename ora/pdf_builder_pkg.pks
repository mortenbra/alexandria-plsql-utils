CREATE OR REPLACE package pdf_builder_pkg
as

  /*

  Purpose:   Package to generate PDF files

  Remarks:   By Anton Scheffer, see http://technology.amis.nl/blog/8650/as_pdf-generating-a-pdf-document-with-some-plsql

  Who     Date        Description
  ------  ----------  -------------------------------------
  ASC     20.10.2010  Created
  
  */

--
  type tp_settings is record
    ( page_width number
    , page_height number
    , margin_left number
    , margin_right number
    , margin_top number
    , margin_bottom number
    , encoding varchar2(100)
    , current_font pls_integer
    , current_fontsizePt pls_integer
    , x   number
    , y   number
    , page_nr pls_integer
    );
--
  procedure init;
--
  function get_pdf
  return blob;
--
  procedure save_pdf
    ( p_dir in varchar2 := 'MY_DIR'
    , p_filename in varchar2 := 'my.pdf'
    );
--
  procedure show_pdf;
--
  function conv2user_units( p_value in number, p_unit in varchar2 )
  return number;
--
  procedure set_format
    ( p_format in varchar2 := 'A4'
    , p_orientation in varchar2 := 'PORTRAIT'
    );
--
  procedure set_pagesize
    ( p_width in number
    , p_height in number
    , p_unit in varchar2 := 'cm'
    );
--
  procedure set_margins
    ( p_top in number := 3
    , p_left in number := 1
    , p_bottom in number := 4
    , p_right in number := 1
    , p_unit in varchar2 := 'cm'
    );
--
  function get_settings
  return tp_settings;
--
  procedure new_page;
--
  procedure set_font
    ( p_family in varchar2
    , p_style  in varchar2 := 'N'
    , p_fontsizePt in pls_integer := null
    , p_encoding in varchar2 := 'WINDOWS-1252'
    );
--
  procedure add2page( p_txt in nclob );
--
  procedure put_txt( p_x in number, p_y in number, p_txt in nclob );
--
  function string_width( p_txt in nclob )
  return number;
--
  procedure write
    ( p_txt in nclob
    , p_x in number := null 
    , p_y in number := null
    , p_line_height in number := null
    , p_start in number := null  -- left side of the available text box
    , p_width in number := null  -- width of the available text box
    , p_alignment in varchar2 := null
    );
--
  procedure set_color( p_rgb in varchar2 := '000000' );
--
  procedure set_color
    ( p_red in number := 0
    , p_green in number := 0
    , p_blue in number := 0 
    );
--
  procedure set_bk_color( p_rgb in varchar2 := 'ffffff' );
--
  procedure set_bk_color
    ( p_red in number := 255
    , p_green in number := 255
    , p_blue in number := 255 
    );
--
  procedure horizontal_line
    ( p_x in number
    , p_y in number
    , p_width in number
    , p_line_width in number := 0.5
    , p_line_color in varchar2 := '000000'
    );
--
  procedure vertical_line
    ( p_x in number
    , p_y in number
    , p_height in number
    , p_line_width in number := 0.5
    , p_line_color in varchar2 := '000000'
    );
--
  procedure rect
    ( p_x in number
    , p_y in number
    , p_width in number
    , p_height in number
    , p_line_color in varchar2 := null
    , p_fill_color in varchar2 := null
    , p_line_width in number := 0.5
    );
--
  procedure put_image
     ( p_dir in varchar2
     , p_file_name in varchar2
     , p_x in number
     , p_y in number
     , p_width in number := null
     , p_height in number := null
     );
--
  procedure put_image
     ( p_url in varchar2
     , p_x in number
     , p_y in number
     , p_width in number := null
     , p_height in number := null
     );
--
  procedure put_image
     ( p_img in blob
     , p_x in number
     , p_y in number
     , p_width in number := null
     , p_height in number := null
     );
--

end pdf_builder_pkg;
/

