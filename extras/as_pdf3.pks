CREATE OR REPLACE package as_pdf3
is
/**********************************************
**
** Author: Anton Scheffer
** Date: 11-04-2012
** Website: http://technology.amis.nl
** See also: http://technology.amis.nl/?p=17718
**
** Changelog:
**   Date: 16-04-2012
**     changed code for parse_png
**   Date: 15-04-2012
**     only dbms_lob.freetemporary for temporary blobs
**   Date: 11-04-2012
**     Initial release of as_pdf3
**
******************************************************************************
******************************************************************************
Copyright (C) 2012 by Anton Scheffer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

******************************************************************************
******************************************** */
--
  c_get_page_width    constant pls_integer := 0;
  c_get_page_height   constant pls_integer := 1;
  c_get_margin_top    constant pls_integer := 2;
  c_get_margin_right  constant pls_integer := 3;
  c_get_margin_bottom constant pls_integer := 4;
  c_get_margin_left   constant pls_integer := 5;
  c_get_x             constant pls_integer := 6;
  c_get_y             constant pls_integer := 7;
  c_get_fontsize      constant pls_integer := 8;
  c_get_current_font  constant pls_integer := 9;
--
  function file2blob( p_dir varchar2, p_file_name varchar2 )
  return blob;
--
  function conv2uu( p_value number, p_unit varchar2 )
  return number;
--
  procedure set_page_size
    ( p_width number
    , p_height number
    , p_unit varchar2 := 'cm'
    );
--
  procedure set_page_format( p_format varchar2 := 'A4' );
--
  procedure set_page_orientation( p_orientation varchar2 := 'PORTRAIT' );
--
  procedure set_margins
    ( p_top number := null
    , p_left number := null
    , p_bottom number := null
    , p_right number := null
    , p_unit varchar2 := 'cm'
    );
--
  procedure set_info
    ( p_title varchar2 := null
    , p_author varchar2 := null
    , p_subject varchar2 := null
    , p_keywords varchar2 := null
    );
--
  procedure init;
--
  function get_pdf
  return blob;
--
  procedure save_pdf
    ( p_dir varchar2 := 'MY_DIR'
    , p_filename varchar2 := 'my.pdf'
    , p_freeblob boolean := true
    );
--
  procedure txt2page( p_txt varchar2 );
--
  procedure put_txt( p_x number, p_y number, p_txt varchar2, p_degrees_rotation number := null );
--
  function str_len( p_txt varchar2 )
  return number;
--
  procedure write
    ( p_txt in varchar2
    , p_x in number := null
    , p_y in number := null
    , p_line_height in number := null
    , p_start in number := null -- left side of the available text box
    , p_width in number := null -- width of the available text box
    , p_alignment in varchar2 := null
    );
--
  procedure set_font
    ( p_index pls_integer
    , p_fontsize_pt number
    , p_output_to_doc boolean := true
    );
--
  function set_font
    ( p_fontname varchar2
    , p_fontsize_pt number
    , p_output_to_doc boolean := true
    )
  return pls_integer;
--
  procedure set_font
    ( p_fontname varchar2
    , p_fontsize_pt number
    , p_output_to_doc boolean := true
    );
--
  function set_font
    ( p_family varchar2
    , p_style varchar2 := 'N'
    , p_fontsize_pt number := null
    , p_output_to_doc boolean := true
    )
  return pls_integer;
--
  procedure set_font
    ( p_family varchar2
    , p_style varchar2 := 'N'
    , p_fontsize_pt number := null
    , p_output_to_doc boolean := true
    );
--
  procedure new_page;
--
  function load_ttf_font
    ( p_font blob
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    , p_offset number := 1
    )
  return pls_integer;
--
  procedure load_ttf_font
    ( p_font blob
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    , p_offset number := 1
    );
--
  function load_ttf_font
    ( p_dir varchar2 := 'MY_FONTS'
    , p_filename varchar2 := 'BAUHS93.TTF'
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    )
  return pls_integer;
--
  procedure load_ttf_font
    ( p_dir varchar2 := 'MY_FONTS'
    , p_filename varchar2 := 'BAUHS93.TTF'
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    );
--
  procedure load_ttc_fonts
    ( p_ttc blob
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    );
--
  procedure load_ttc_fonts
    ( p_dir varchar2 := 'MY_FONTS'
    , p_filename varchar2 := 'CAMBRIA.TTC'
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    );
--
  procedure set_color( p_rgb varchar2 := '000000' );
--
  procedure set_color
    ( p_red number := 0
    , p_green number := 0
    , p_blue number := 0
    );
--
  procedure set_bk_color( p_rgb varchar2 := 'ffffff' );
--
  procedure set_bk_color
    ( p_red number := 0
    , p_green number := 0
    , p_blue number := 0
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
  function get( p_what in pls_integer )
  return number;
--
  procedure put_image
    ( p_img blob
    , p_x number
    , p_y number
    , p_width number := null
    , p_height number := null
    , p_align varchar2 := 'center'
    , p_valign varchar2 := 'top'
    );
--
  procedure put_image
    ( p_dir varchar2
    , p_file_name varchar2
    , p_x number
    , p_y number
    , p_width number := null
    , p_height number := null
    , p_align varchar2 := 'center'
    , p_valign varchar2 := 'top'
    );
--
  procedure put_image
    ( p_url varchar2
    , p_x number
    , p_y number
    , p_width number := null
    , p_height number := null
    , p_align varchar2 := 'center'
    , p_valign varchar2 := 'top'
    );
--
  procedure set_page_proc( p_src clob );
--
  type tp_col_widths is table of number;
  type tp_headers is table of varchar2(32767);
--
  procedure query2table
    ( p_query varchar2
    , p_widths tp_col_widths := null
    , p_headers tp_headers := null
    );
--
$IF not DBMS_DB_VERSION.VER_LE_10 $THEN
  procedure refcursor2table
    ( p_rc sys_refcursor
    , p_widths tp_col_widths := null
    , p_headers tp_headers := null
    );
--
$END
end as_pdf3;
/

