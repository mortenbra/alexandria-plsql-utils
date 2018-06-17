create or replace package xlsx_builder_pkg
authid current_user as
/**********************************************
**
** Author: Anton Scheffer
** Date: 19-02-2011
** Website: http://technology.amis.nl/blog
** See also: http://technology.amis.nl/blog/?p=10995
** See also: https://technology.amis.nl/2011/02/19/create-an-excel-file-with-plsql/
**
** Changelog:
**   Date: 21-02-2011
**     Added Aligment, horizontal, vertical, wrapText
**   Date: 06-03-2011
**     Added Comments, MergeCells, fixed bug for dependency on NLS-settings
**   Date: 16-03-2011
**     Added bold and italic fonts
**   Date: 22-03-2011
**     Fixed issue with timezone's set to a region(name) instead of a offset
**   Date: 08-04-2011
**     Fixed issue with XML-escaping from text
**   Date: 27-05-2011
**     Added MIT-license
**   Date: 11-08-2011
**     Fixed NLS-issue with column width
**   Date: 29-09-2011
**     Added font color
**   Date: 16-10-2011
**     fixed bug in add_string
**   Date: 26-04-2012
**     Fixed set_autofilter (only one autofilter per sheet, added _xlnm._FilterDatabase)
**     Added list_validation = drop-down 
**   Date: 27-08-2013
**     Added freeze_pane
**
******************************************************************************
******************************************************************************
Copyright (C) 2011, 2012 by Anton Scheffer

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
  type tp_alignment is record
    ( vertical varchar2(11)
    , horizontal varchar2(16)
    , wrapText boolean
    );
--
  procedure clear_workbook;
--
  procedure new_sheet( p_sheetname varchar2 := null );
--
  function OraFmt2Excel( p_format varchar2 := null )
  return varchar2;
--
  function get_numFmt( p_format varchar2 := null )
  return pls_integer;
--
  function get_font
    ( p_name varchar2
    , p_family pls_integer := 2
    , p_fontsize number := 11
    , p_theme pls_integer := 1
    , p_underline boolean := false
    , p_italic boolean := false
    , p_bold boolean := false
    , p_rgb varchar2 := null -- this is a hex ALPHA Red Green Blue value
    )
  return pls_integer;
--
  function get_fill
    ( p_patternType varchar2
    , p_fgRGB varchar2 := null -- this is a hex ALPHA Red Green Blue value
    )
  return pls_integer;
--
  function get_border
    ( p_top varchar2 := 'thin'
    , p_bottom varchar2 := 'thin'
    , p_left varchar2 := 'thin'
    , p_right varchar2 := 'thin'
    )
/*
none
thin
medium
dashed
dotted
thick
double
hair
mediumDashed
dashDot
mediumDashDot
dashDotDot
mediumDashDotDot
slantDashDot
*/
  return pls_integer;
--
  function get_alignment
    ( p_vertical varchar2 := null
    , p_horizontal varchar2 := null
    , p_wrapText boolean := null
    )
/* horizontal
center
centerContinuous
distributed
fill
general
justify
left
right
*/
/* vertical
bottom
center
distributed
justify
top
*/
  return tp_alignment;
--
  procedure cell
    ( p_col pls_integer
    , p_row pls_integer
    , p_value number
    , p_numFmtId pls_integer := null
    , p_fontId pls_integer := null
    , p_fillId pls_integer := null
    , p_borderId pls_integer := null
    , p_alignment tp_alignment := null
    , p_sheet pls_integer := null
    );
--
  procedure cell
    ( p_col pls_integer
    , p_row pls_integer
    , p_value varchar2
    , p_numFmtId pls_integer := null
    , p_fontId pls_integer := null
    , p_fillId pls_integer := null
    , p_borderId pls_integer := null
    , p_alignment tp_alignment := null
    , p_sheet pls_integer := null
    );
--
  procedure cell
    ( p_col pls_integer
    , p_row pls_integer
    , p_value date
    , p_numFmtId pls_integer := null
    , p_fontId pls_integer := null
    , p_fillId pls_integer := null
    , p_borderId pls_integer := null
    , p_alignment tp_alignment := null
    , p_sheet pls_integer := null
    );
--
  procedure hyperlink
    ( p_col pls_integer
    , p_row pls_integer
    , p_url varchar2
    , p_value varchar2 := null
    , p_sheet pls_integer := null
    );
--
  procedure comment
    ( p_col pls_integer
    , p_row pls_integer
    , p_text varchar2
    , p_author varchar2 := null
    , p_width pls_integer := 150  -- pixels
    , p_height pls_integer := 100  -- pixels
    , p_sheet pls_integer := null
    );
--
  procedure mergecells
    ( p_tl_col pls_integer -- top left
    , p_tl_row pls_integer
    , p_br_col pls_integer -- bottom right
    , p_br_row pls_integer
    , p_sheet pls_integer := null
    );
--
  procedure list_validation
    ( p_sqref_col pls_integer
    , p_sqref_row pls_integer
    , p_tl_col pls_integer -- top left
    , p_tl_row pls_integer
    , p_br_col pls_integer -- bottom right
    , p_br_row pls_integer
    , p_style varchar2 := 'stop' -- stop, warning, information
    , p_title varchar2 := null
    , p_prompt varchar := null
    , p_show_error boolean := false
    , p_error_title varchar2 := null
    , p_error_txt varchar2 := null
    , p_sheet pls_integer := null
    );
--
  procedure list_validation
    ( p_sqref_col pls_integer
    , p_sqref_row pls_integer
    , p_defined_name varchar2
    , p_style varchar2 := 'stop' -- stop, warning, information
    , p_title varchar2 := null
    , p_prompt varchar := null
    , p_show_error boolean := false
    , p_error_title varchar2 := null
    , p_error_txt varchar2 := null
    , p_sheet pls_integer := null
    );
--
  procedure defined_name
    ( p_tl_col pls_integer -- top left
    , p_tl_row pls_integer
    , p_br_col pls_integer -- bottom right
    , p_br_row pls_integer
    , p_name varchar2
    , p_sheet pls_integer := null
    , p_localsheet pls_integer := null
    );
--
  procedure set_column_width
    ( p_col pls_integer
    , p_width number
    , p_sheet pls_integer := null
    );
--
  procedure set_column
    ( p_col pls_integer
    , p_numFmtId pls_integer := null
    , p_fontId pls_integer := null
    , p_fillId pls_integer := null
    , p_borderId pls_integer := null
    , p_alignment tp_alignment := null
    , p_sheet pls_integer := null
    );
--
  procedure set_row
    ( p_row pls_integer
    , p_numFmtId pls_integer := null
    , p_fontId pls_integer := null
    , p_fillId pls_integer := null
    , p_borderId pls_integer := null
    , p_alignment tp_alignment := null
    , p_sheet pls_integer := null
    );
--
  procedure freeze_rows
    ( p_nr_rows pls_integer := 1
    , p_sheet pls_integer := null
    );
--
  procedure freeze_cols
    ( p_nr_cols pls_integer := 1
    , p_sheet pls_integer := null
    );
--
  procedure freeze_pane
    ( p_col pls_integer
    , p_row pls_integer
    , p_sheet pls_integer := null
    );
--
  procedure set_autofilter
    ( p_column_start pls_integer := null
    , p_column_end pls_integer := null
    , p_row_start pls_integer := null
    , p_row_end pls_integer := null
    , p_sheet pls_integer := null
    );
--
  function finish
  return blob;
--
  procedure save
    ( p_directory varchar2
    , p_filename varchar2
    );
--
  procedure query2sheet
    ( p_sql varchar2
    , p_column_headers boolean := true
    , p_directory varchar2 := null
    , p_filename varchar2 := null
    , p_sheet pls_integer := null
    );
end;
/
