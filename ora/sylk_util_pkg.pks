create or replace package sylk_util_pkg
as
 
  /*
 
  Purpose:      Package handles SYLK format (SLK)
 
  Remarks:      by Tom Kyte, see http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:728625409049
                see http://en.wikipedia.org/wiki/SYmbolic_LinK_(SYLK)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.01.2011  Created
 
  */

  type owaSylkArray is table of varchar2(2000);

  procedure show(
      p_file          in utl_file.file_type,
      p_query         in varchar2,
      p_parm_names    in owaSylkArray default owaSylkArray(),
      p_parm_values   in owaSylkArray default owaSylkArray(),
      p_sum_column    in owaSylkArray default owaSylkArray(),
      p_max_rows      in number     default 10000,
      p_show_null_as  in varchar2   default null,
      p_show_grid     in varchar2   default 'YES',
      p_show_col_headers in varchar2 default 'YES',
      p_font_name     in varchar2   default 'Courier New',
      p_widths        in owaSylkArray default owaSylkArray(),
      p_titles        in owaSylkArray default owaSylkArray(),
      p_strip_html    in varchar2   default 'YES' );

  procedure show(
      p_file          in utl_file.file_type,
      p_cursor        in integer,
      p_sum_column    in owaSylkArray  default owaSylkArray(),
      p_max_rows      in number     default 10000,
      p_show_null_as  in varchar2   default null,
      p_show_grid     in varchar2   default 'YES',
      p_show_col_headers in varchar2 default 'YES',
      p_font_name     in varchar2   default 'Courier New',
      p_widths        in owaSylkArray default owaSylkArray(),
      p_titles        in owaSylkArray default owaSylkArray(),
      p_strip_html    in varchar2   default 'YES' );


end sylk_util_pkg;
/

