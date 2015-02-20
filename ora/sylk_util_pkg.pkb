create or replace package body sylk_util_pkg
as
 
  /*
 
  Purpose:      Package handles SYLK format (SLK)
 
  Remarks:      by Tom Kyte, see http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:728625409049
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.01.2011  Created
 
  */
 
 
  g_cvalue  varchar2(32767);
  g_desc_t  dbms_sql.desc_tab;

  type vc_arr is table of varchar2(2000) index by binary_integer;
  g_lengths vc_arr;
  g_sums vc_arr;

  g_file  utl_file.file_type;


procedure p( p_str in varchar2 )
is
begin
  utl_file.put_line( g_file, p_str );
end;


function build_cursor(
    q in varchar2,
    n in owaSylkArray,
    v in owaSylkArray ) return integer
is
  c integer := dbms_sql.open_cursor;
  i number := 1;
begin
  dbms_sql.parse (c, q, dbms_sql.native);
  while i <= n.count  loop
    dbms_sql.bind_variable( c, n(i), v(i) );
    i := i + 1;
  end loop;
  return c;
end build_cursor;


function str_html ( line in varchar2 ) return varchar2
is
  x       varchar2(32767) := null;
  in_html boolean         := FALSE;
  s       varchar2(1);
begin
  if line is null then
    return line;
  end if;
  for i in 1 .. length( line ) loop
    s := substr( line, i, 1 );
    if in_html then
      if s = '>' then
        in_html := FALSE;
      end if;
    else
      if s = '<' then
        in_html := TRUE;
      end if;
    end if;
    if not in_html and s != '>' then
      x := x || s;
    end if;
  end loop;
  return x;
end str_html;


function ite( b boolean,
              t varchar2,
              f varchar2 ) return varchar2
is
begin
  if b then
    return t;
  else
    return f;
  end if;
end ite;


procedure print_comment( p_comment varchar2 )
is
begin
  return;
  p( ';' || chr(10) || '; ' || p_comment || chr(10) || ';' );
end print_comment;


procedure print_heading( font in varchar2, 
                         grid in varchar2, 
                         col_heading in varchar2, 
                         titles in owaSylkArray ) 
is
  l_title varchar2(2000);
begin
  p( 'ID;ORACLE' );
  print_comment( 'Fonts' );
  p( 'P;F' || font || ';M200' );
  p( 'P;F' || font || ';M200;SB' );
  p( 'P;F' || font || ';M200;SUB' );

  print_comment( 'Global Formatting' );
  p( 'F;C1;FG0R;SM1' || 
         ite( upper(grid)='YES', '', ';G' ) || 
         ite( upper(col_heading)='YES', '', ';H' )  );
  for i in 1 .. g_desc_t.count loop
    p( 'F;C' || to_char(i+1) || ';FG0R;SM0' );
  end loop;

  print_comment( 'Title Row' );
  p( 'F;R1;FG0C;SM2' );
  for i in 1 .. g_desc_t.count loop
    g_lengths(i) := g_desc_t(i).col_name_len;
    g_sums(i) := 0;
    begin
      l_title := titles(i);
    exception
      when others then
        l_title := g_desc_t(i).col_name;
    end;
    if i = 1 then
      p( 'C;Y1;X2;K"' || l_title || '"' );
    else
      p( 'C;X' || to_char(i+1) || ';K"' || l_title || '"' );
    end if;
  end loop;
end print_heading;


function print_rows(
    c            in integer,
    max_rows     in number,
    sum_columns  in owaSylkArray,
    show_null_as in varchar2,
    strip_html   in varchar2 ) return number is
  row_cnt number          := 0;
  line    varchar2(32767) := null;
  n       number;
begin
  loop
    exit when ( row_cnt >= max_rows or
                dbms_sql.fetch_rows( c ) <= 0 );
    row_cnt := row_cnt + 1;
    print_comment( 'Row ' || row_cnt );
    --
    p( 'C;Y' || to_char(row_cnt+2) );

    for i in 1 .. g_desc_t.count loop
      dbms_sql.column_value( c, i, g_cvalue );
      g_cvalue := translate( g_cvalue, 
                          chr(10)||chr(9)||';', '   ' );
      g_cvalue := ite( upper( strip_html ) = 'YES',
                           str_html( g_cvalue ),
                           g_cvalue );
      g_lengths(i) := greatest( nvl(length(g_cvalue), 
                                nvl(length(show_null_as),0)),
                                g_lengths(i) );
      line := 'C;X' || to_char(i+1);
      line := line || ';K';
      begin
        n := to_number( g_cvalue );
        if upper( sum_columns(i)) = 'Y' then
          g_sums(i) := g_sums(i) + nvl(n,0);
        end if;
      exception
        when others then
          n := null;
      end;
      line := line || 
               ite( n is null, 
                    ite( g_cvalue is null, 
                             '"'||show_null_as||
                                '"', '"'||g_cvalue||'"' ), 
                           n );
      p( line );
    end loop;
    --
  end loop;
  return row_cnt;
end print_rows;


procedure print_sums(
    sum_columns  in owaSylkArray,
    row_cnt      in number )
is
begin
  if sum_columns.count = 0 then
    return;
  end if;

  print_comment( 'Totals Row' );
  p( 'C;Y' || to_char(row_cnt + 4) );
  p( 'C;X1;K"Totals:"' );

  for i in 1 .. g_desc_t.count loop
    begin
      if upper(sum_columns(i)) = 'Y' then
        p( 'C;X' || to_char(i+1) || ';ESUM(R3C:R' || 
                to_char(row_cnt+2) || 'C)' );
      end if;
    end;
  end loop;
end print_sums;


procedure print_widths( widths owaSylkArray )
is
begin
  print_comment( 'Format Column Widths' );
  p( 'F;W1 1 7' );
  for i in 1 .. g_desc_t.count loop
    begin
      p( 'F;W' || to_char(i+1) || ' ' || 
          to_char(i+1) || ' ' || 
          to_char(to_number(widths(i))) );
    exception
      when others then
        p( 'F;W' || to_char(i+1) || ' ' || 
             to_char(i+1) || ' ' || 
             greatest( g_lengths(i), length( g_sums(i) )));
    end;
  end loop;
  p( 'E' );
end print_widths;


procedure show(
    p_file          in utl_file.file_type,
    p_cursor        in integer,
    p_sum_column    in owaSylkArray default owaSylkArray(),
    p_max_rows      in number     default 10000,
    p_show_null_as  in varchar2   default null,
    p_show_grid     in varchar2   default 'YES',
    p_show_col_headers in varchar2 default 'YES',
    p_font_name     in varchar2   default 'Courier New',
    p_widths        in owaSylkArray default owaSylkArray(),
    p_titles        in owaSylkArray default owaSylkArray(),
    p_strip_html    in varchar2   default 'YES' )
is
  l_row_cnt number;
  l_col_cnt number;
  l_status  number;
begin
  g_file := p_file;
  dbms_sql.describe_columns( p_cursor, l_col_cnt, g_desc_t );
  --
  for i in 1 .. g_desc_t.count loop
    dbms_sql.define_column( p_cursor, i, g_cvalue, 32765);
  end loop;
  --
  print_heading( p_font_name, 
                 p_show_grid, 
                 p_show_col_headers, 
                 p_titles );
  l_status := dbms_sql.execute( p_cursor );
  l_row_cnt := print_rows(
                 p_cursor, 
                 p_max_rows,
                 p_sum_column,
                 p_show_null_as,
                 p_strip_html );
  print_sums( p_sum_column, l_row_cnt );
  print_widths( p_widths );
end show;


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
    p_strip_html    in varchar2   default 'YES' )
is
begin
  show( p_file => p_file,
        p_cursor => build_cursor( p_query, 
                                  p_parm_names, 
                                  p_parm_values ),
        p_sum_column => p_sum_column,
        p_max_rows => p_max_rows,
        p_show_null_as => p_show_null_as,
        p_show_grid => p_show_grid,
        p_show_col_headers => p_show_col_headers,
        p_font_name => p_font_name,
        p_widths => p_widths,
        p_titles => p_titles,
        p_strip_html => p_strip_html );
end show;

end sylk_util_pkg;
/
 
