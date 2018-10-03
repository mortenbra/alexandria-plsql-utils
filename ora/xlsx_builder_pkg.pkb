CREATE OR REPLACE package body xlsx_builder_pkg
as 
--
  c_LOCAL_FILE_HEADER        constant raw(4) := hextoraw( '504B0304' ); -- Local file header signature
  c_END_OF_CENTRAL_DIRECTORY constant raw(4) := hextoraw( '504B0506' ); -- End of central directory signature
--
  type tp_XF_fmt is record
    ( numFmtId pls_integer
    , fontId pls_integer
    , fillId pls_integer
    , borderId pls_integer
    , alignment tp_alignment
    );
  type tp_col_fmts is table of tp_XF_fmt index by pls_integer;
  type tp_row_fmts is table of tp_XF_fmt index by pls_integer;
  type tp_widths is table of number index by pls_integer;
  type tp_cell is record
    ( value number
    , style varchar2(50)
    );
  type tp_cells is table of tp_cell index by pls_integer;
  type tp_rows is table of tp_cells index by pls_integer;
  type tp_autofilter is record
    ( column_start pls_integer
    , column_end pls_integer
    , row_start pls_integer
    , row_end pls_integer
    );
  type tp_autofilters is table of tp_autofilter index by pls_integer;
  type tp_hyperlink is record
    ( cell varchar2(10)
    , url  varchar2(1000)
    );
  type tp_hyperlinks is table of tp_hyperlink index by pls_integer;
  subtype tp_author is varchar2(32767 char);
  type tp_authors is table of pls_integer index by tp_author;
  authors tp_authors;
  type tp_comment is record
    ( text varchar2(32767 char)
    , author tp_author
    , row pls_integer
    , column pls_integer
    , width pls_integer
    , height pls_integer
    );
  type tp_comments is table of tp_comment index by pls_integer;
  type tp_mergecells is table of varchar2(21) index by pls_integer;
  type tp_validation is record
    ( type varchar2(10)
    , errorstyle varchar2(32)
    , showinputmessage boolean
    , prompt varchar2(32767 char)
    , title varchar2(32767 char)
    , error_title varchar2(32767 char)
    , error_txt varchar2(32767 char)
    , showerrormessage boolean
    , formula1 varchar2(32767 char)
    , formula2 varchar2(32767 char)
    , allowBlank boolean
    , sqref varchar2(32767 char)
    );
  type tp_validations is table of tp_validation index by pls_integer;
  type tp_sheet is record
    ( rows tp_rows
    , widths tp_widths
    , name varchar2(100)
    , freeze_rows pls_integer
    , freeze_cols pls_integer
    , autofilters tp_autofilters
    , hyperlinks tp_hyperlinks
    , col_fmts tp_col_fmts
    , row_fmts tp_row_fmts
    , comments tp_comments
    , mergecells tp_mergecells
    , validations tp_validations
    );
  type tp_sheets is table of tp_sheet index by pls_integer;
  type tp_numFmt is record
    ( numFmtId pls_integer
    , formatCode varchar2(100)
    );
  type tp_numFmts is table of tp_numFmt index by pls_integer;
  type tp_fill is record
    ( patternType varchar2(30)
    , fgRGB varchar2(8)
    );
  type tp_fills is table of tp_fill index by pls_integer;
  type tp_cellXfs is table of tp_xf_fmt index by pls_integer;
  type tp_font is record
    ( name varchar2(100)
    , family pls_integer
    , fontsize number
    , theme pls_integer
    , RGB varchar2(8)
    , underline boolean
    , italic boolean
    , bold boolean
    );
  type tp_fonts is table of tp_font index by pls_integer;
  type tp_border is record
    ( top varchar2(17)
    , bottom varchar2(17)
    , left varchar2(17)
    , right varchar2(17)
    );
  type tp_borders is table of tp_border index by pls_integer;
  type tp_numFmtIndexes is table of pls_integer index by pls_integer;
  type tp_strings is table of pls_integer index by varchar2(32767 char);
  type tp_str_ind is table of varchar2(32767 char) index by pls_integer;
  type tp_defined_name is record
    ( name varchar2(32767 char)
    , ref varchar2(32767 char)
    , sheet pls_integer
    );
  type tp_defined_names is table of tp_defined_name index by pls_integer;
  type tp_book is record
    ( sheets tp_sheets
    , strings tp_strings
    , str_ind tp_str_ind
    , str_cnt pls_integer := 0
    , fonts tp_fonts
    , fills tp_fills
    , borders tp_borders
    , numFmts tp_numFmts
    , cellXfs tp_cellXfs
    , numFmtIndexes tp_numFmtIndexes
    , defined_names tp_defined_names
    );
  workbook tp_book;
--
  procedure blob2file
    ( p_blob blob
    , p_directory varchar2 := 'MY_DIR'
    , p_filename varchar2 := 'my.xlsx'
    )
  is
    t_fh utl_file.file_type;
    t_len pls_integer := 32767;
  begin
    t_fh := utl_file.fopen( p_directory
                          , p_filename
                          , 'wb'
                          );
    for i in 0 .. trunc( ( dbms_lob.getlength( p_blob ) - 1 ) / t_len )
    loop
      utl_file.put_raw( t_fh
                      , dbms_lob.substr( p_blob
                                       , t_len
                                       , i * t_len + 1
                                       )
                      );
    end loop;
    utl_file.fclose( t_fh );
  end;
--
  function raw2num( p_raw raw, p_len integer, p_pos integer )
  return number
  is
  begin
    return utl_raw.cast_to_binary_integer( utl_raw.substr( p_raw, p_pos, p_len ), utl_raw.little_endian );
  end;
--
  function little_endian( p_big number, p_bytes pls_integer := 4 )
  return raw
  is
  begin
    return utl_raw.substr( utl_raw.cast_from_binary_integer( p_big, utl_raw.little_endian ), 1, p_bytes );
  end;
--
  function blob2num( p_blob blob, p_len integer, p_pos integer )
  return number
  is
  begin
    return utl_raw.cast_to_binary_integer( dbms_lob.substr( p_blob, p_len, p_pos ), utl_raw.little_endian );
  end;
--
  procedure add1file
    ( p_zipped_blob in out blob
    , p_name varchar2
    , p_content blob
    )
  is
    t_now date;
    t_blob blob;
    t_len integer;
    t_clen integer;
    t_crc32 raw(4) := hextoraw( '00000000' );
    t_compressed boolean := false;
    t_name raw(32767);
  begin
    t_now := sysdate;
    t_len := nvl( dbms_lob.getlength( p_content ), 0 );
    if t_len > 0
    then 
      t_blob := utl_compress.lz_compress( p_content );
      t_clen := dbms_lob.getlength( t_blob ) - 18;
      t_compressed := t_clen < t_len;
      t_crc32 := dbms_lob.substr( t_blob, 4, t_clen + 11 );       
    end if;
    if not t_compressed
    then 
      t_clen := t_len;
      t_blob := p_content;
    end if;
    if p_zipped_blob is null
    then
      dbms_lob.createtemporary( p_zipped_blob, true );
    end if;
    t_name := utl_i18n.string_to_raw( p_name, 'AL32UTF8' );
    dbms_lob.append( p_zipped_blob
                   , utl_raw.concat( c_LOCAL_FILE_HEADER -- Local file header signature
                                   , hextoraw( '1400' )  -- version 2.0
                                   , case when t_name = utl_i18n.string_to_raw( p_name, 'US8PC437' )
                                       then hextoraw( '0000' ) -- no General purpose bits
                                       else hextoraw( '0008' ) -- set Language encoding flag (EFS)
                                     end 
                                   , case when t_compressed
                                        then hextoraw( '0800' ) -- deflate
                                        else hextoraw( '0000' ) -- stored
                                     end
                                   , little_endian( to_number( to_char( t_now, 'ss' ) ) / 2
                                                  + to_number( to_char( t_now, 'mi' ) ) * 32
                                                  + to_number( to_char( t_now, 'hh24' ) ) * 2048
                                                  , 2
                                                  ) -- File last modification time
                                   , little_endian( to_number( to_char( t_now, 'dd' ) )
                                                  + to_number( to_char( t_now, 'mm' ) ) * 32
                                                  + ( to_number( to_char( t_now, 'yyyy' ) ) - 1980 ) * 512
                                                  , 2
                                                  ) -- File last modification date
                                   , t_crc32 -- CRC-32
                                   , little_endian( t_clen )                      -- compressed size
                                   , little_endian( t_len )                       -- uncompressed size
                                   , little_endian( utl_raw.length( t_name ), 2 ) -- File name length
                                   , hextoraw( '0000' )                           -- Extra field length
                                   , t_name                                       -- File name
                                   )
                   );
    if t_compressed
    then                   
      dbms_lob.copy( p_zipped_blob, t_blob, t_clen, dbms_lob.getlength( p_zipped_blob ) + 1, 11 ); -- compressed content
    elsif t_clen > 0
    then                   
      dbms_lob.copy( p_zipped_blob, t_blob, t_clen, dbms_lob.getlength( p_zipped_blob ) + 1, 1 ); --  content
    end if;
    if dbms_lob.istemporary( t_blob ) = 1
    then      
      dbms_lob.freetemporary( t_blob );
    end if;
  end;
--
  procedure finish_zip( p_zipped_blob in out blob )
  is
    t_cnt pls_integer := 0;
    t_offs integer;
    t_offs_dir_header integer;
    t_offs_end_header integer;
    t_comment raw(32767) := utl_raw.cast_to_raw( 'Implementation by Anton Scheffer' );
  begin
    t_offs_dir_header := dbms_lob.getlength( p_zipped_blob );
    t_offs := 1;
    while dbms_lob.substr( p_zipped_blob, utl_raw.length( c_LOCAL_FILE_HEADER ), t_offs ) = c_LOCAL_FILE_HEADER
    loop
      t_cnt := t_cnt + 1;
      dbms_lob.append( p_zipped_blob
                     , utl_raw.concat( hextoraw( '504B0102' )      -- Central directory file header signature
                                     , hextoraw( '1400' )          -- version 2.0
                                     , dbms_lob.substr( p_zipped_blob, 26, t_offs + 4 )
                                     , hextoraw( '0000' )          -- File comment length
                                     , hextoraw( '0000' )          -- Disk number where file starts
                                     , hextoraw( '0000' )          -- Internal file attributes => 
                                                                   --     0000 binary file
                                                                   --     0100 (ascii)text file
                                     , case
                                         when dbms_lob.substr( p_zipped_blob
                                                             , 1
                                                             , t_offs + 30 + blob2num( p_zipped_blob, 2, t_offs + 26 ) - 1
                                                             ) in ( hextoraw( '2F' ) -- /
                                                                  , hextoraw( '5C' ) -- \
                                                                  )
                                         then hextoraw( '10000000' ) -- a directory/folder
                                         else hextoraw( '2000B681' ) -- a file
                                       end                         -- External file attributes
                                     , little_endian( t_offs - 1 ) -- Relative offset of local file header
                                     , dbms_lob.substr( p_zipped_blob
                                                      , blob2num( p_zipped_blob, 2, t_offs + 26 )
                                                      , t_offs + 30
                                                      )            -- File name
                                     )
                     );
      t_offs := t_offs + 30 + blob2num( p_zipped_blob, 4, t_offs + 18 )  -- compressed size
                            + blob2num( p_zipped_blob, 2, t_offs + 26 )  -- File name length 
                            + blob2num( p_zipped_blob, 2, t_offs + 28 ); -- Extra field length
    end loop;
    t_offs_end_header := dbms_lob.getlength( p_zipped_blob );
    dbms_lob.append( p_zipped_blob
                   , utl_raw.concat( c_END_OF_CENTRAL_DIRECTORY                                -- End of central directory signature
                                   , hextoraw( '0000' )                                        -- Number of this disk
                                   , hextoraw( '0000' )                                        -- Disk where central directory starts
                                   , little_endian( t_cnt, 2 )                                 -- Number of central directory records on this disk
                                   , little_endian( t_cnt, 2 )                                 -- Total number of central directory records
                                   , little_endian( t_offs_end_header - t_offs_dir_header )    -- Size of central directory
                                   , little_endian( t_offs_dir_header )                        -- Offset of start of central directory, relative to start of archive
                                   , little_endian( nvl( utl_raw.length( t_comment ), 0 ), 2 ) -- ZIP file comment length
                                   , t_comment
                                   )
                   );
  end;
--
  function alfan_col( p_col pls_integer )
  return varchar2
  is
  begin
    return case
             when p_col > 702 then chr( 64 + trunc( ( p_col - 27 ) / 676 ) ) || chr( 65 + mod( trunc( ( p_col - 1 ) / 26 ) - 1, 26 ) ) || chr( 65 + mod( p_col - 1, 26 ) )
             when p_col > 26  then chr( 64 + trunc( ( p_col - 1 ) / 26 ) ) || chr( 65 + mod( p_col - 1, 26 ) )
             else chr( 64 + p_col )
           end;
  end;
--
  function col_alfan( p_col varchar2 )
  return pls_integer
  is
  begin
    return ascii( substr( p_col, -1 ) ) - 64
         + nvl( ( ascii( substr( p_col, -2, 1 ) ) - 64 ) * 26, 0 )
         + nvl( ( ascii( substr( p_col, -3, 1 ) ) - 64 ) * 676, 0 );
  end;
--
  procedure clear_workbook
  is
    t_row_ind pls_integer;
  begin
    for s in 1 .. workbook.sheets.count()
    loop
      t_row_ind := workbook.sheets( s ).rows.first();
      while t_row_ind is not null
      loop
        workbook.sheets( s ).rows( t_row_ind ).delete();
        t_row_ind := workbook.sheets( s ).rows.next( t_row_ind );
      end loop;
      workbook.sheets( s ).rows.delete();
      workbook.sheets( s ).widths.delete();
      workbook.sheets( s ).autofilters.delete();
      workbook.sheets( s ).hyperlinks.delete();
      workbook.sheets( s ).col_fmts.delete();
      workbook.sheets( s ).row_fmts.delete();
      workbook.sheets( s ).comments.delete();
      workbook.sheets( s ).mergecells.delete();
      workbook.sheets( s ).validations.delete();
    end loop;
    workbook.strings.delete();
    workbook.str_ind.delete();
    workbook.fonts.delete();
    workbook.fills.delete();
    workbook.borders.delete();
    workbook.numFmts.delete();
    workbook.cellXfs.delete();
    workbook.defined_names.delete();
    workbook := null;
  end;
--
  procedure new_sheet( p_sheetname varchar2 := null )
  is
    t_nr pls_integer := workbook.sheets.count() + 1;
    t_ind pls_integer;
  begin
    workbook.sheets( t_nr ).name := nvl( dbms_xmlgen.convert( translate( p_sheetname, 'a/\[]*:?', 'a' ) ), 'Sheet' || t_nr );
    if workbook.strings.count() = 0
    then
     workbook.str_cnt := 0;
    end if;
    if workbook.fonts.count() = 0
    then
      t_ind := get_font( 'Calibri' );
    end if;
    if workbook.fills.count() = 0
    then
      t_ind := get_fill( 'none' );
      t_ind := get_fill( 'gray125' );
    end if;
    if workbook.borders.count() = 0
    then
      t_ind := get_border( '', '', '', '' );
    end if;
  end;
--
  procedure set_col_width
    ( p_sheet pls_integer
    , p_col pls_integer
    , p_format varchar2
    )
  is
    t_width number;
    t_nr_chr pls_integer;
  begin
    if p_format is null
    then
      return;
    end if;
    if instr( p_format, ';' ) > 0
    then
      t_nr_chr := length( translate( substr( p_format, 1, instr( p_format, ';' ) - 1 ), 'a\"', 'a' ) );
    else
      t_nr_chr := length( translate( p_format, 'a\"', 'a' ) );
    end if;
    t_width := trunc( ( t_nr_chr * 7 + 5 ) / 7 * 256 ) / 256; -- assume default 11 point Calibri
    if workbook.sheets( p_sheet ).widths.exists( p_col )
    then
      workbook.sheets( p_sheet ).widths( p_col ) :=
        greatest( workbook.sheets( p_sheet ).widths( p_col )
                , t_width
                );
    else
      workbook.sheets( p_sheet ).widths( p_col ) := greatest( t_width, 8.43 );
    end if;
  end;
--
  function OraFmt2Excel( p_format varchar2 := null )
  return varchar2
  is
    t_format varchar2(1000) := substr( p_format, 1, 1000 );
  begin
    t_format := replace( replace( t_format, 'hh24', 'hh' ), 'hh12', 'hh' );
    t_format := replace( t_format, 'mi', 'mm' );
    t_format := replace( replace( replace( t_format, 'AM', '~~' ), 'PM', '~~' ), '~~', 'AM/PM' );
    t_format := replace( replace( replace( t_format, 'am', '~~' ), 'pm', '~~' ), '~~', 'AM/PM' );
    t_format := replace( replace( t_format, 'day', 'DAY' ), 'DAY', 'dddd' );
    t_format := replace( replace( t_format, 'dy', 'DY' ), 'DAY', 'ddd' );
    t_format := replace( replace( t_format, 'RR', 'RR' ), 'RR', 'YY' );
    t_format := replace( replace( t_format, 'month', 'MONTH' ), 'MONTH', 'mmmm' );
    t_format := replace( replace( t_format, 'mon', 'MON' ), 'MON', 'mmm' );
    return t_format;
  end;
--
  function get_numFmt( p_format varchar2 := null )
  return pls_integer
  is
    t_cnt pls_integer;
    t_numFmtId pls_integer;
  begin
    if p_format is null
    then
      return 0;
    end if;
    t_cnt := workbook.numFmts.count();
    for i in 1 .. t_cnt
    loop
      if workbook.numFmts( i ).formatCode = p_format
      then
        t_numFmtId := workbook.numFmts( i ).numFmtId;
        exit;
      end if;
    end loop;
    if t_numFmtId is null
    then
      t_numFmtId := case when t_cnt = 0 then 164 else workbook.numFmts( t_cnt ).numFmtId + 1 end;
      t_cnt := t_cnt + 1;
      workbook.numFmts( t_cnt ).numFmtId := t_numFmtId;
      workbook.numFmts( t_cnt ).formatCode := p_format;
      workbook.numFmtIndexes( t_numFmtId ) := t_cnt;
    end if;
    return t_numFmtId;
  end;
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
  return pls_integer
  is
    t_ind pls_integer;
  begin
    if workbook.fonts.count() > 0
    then
      for f in 0 .. workbook.fonts.count() - 1
      loop
        if (   workbook.fonts( f ).name = p_name
           and workbook.fonts( f ).family = p_family
           and workbook.fonts( f ).fontsize = p_fontsize
           and workbook.fonts( f ).theme = p_theme
           and workbook.fonts( f ).underline = p_underline
           and workbook.fonts( f ).italic = p_italic
           and workbook.fonts( f ).bold = p_bold
           and ( workbook.fonts( f ).rgb = p_rgb
               or ( workbook.fonts( f ).rgb is null and p_rgb is null )
               )
           )
        then
          return f;
        end if;
      end loop;
    end if;
    t_ind := workbook.fonts.count();
    workbook.fonts( t_ind ).name := p_name;
    workbook.fonts( t_ind ).family := p_family;
    workbook.fonts( t_ind ).fontsize := p_fontsize;
    workbook.fonts( t_ind ).theme := p_theme;
    workbook.fonts( t_ind ).underline := p_underline;
    workbook.fonts( t_ind ).italic := p_italic;
    workbook.fonts( t_ind ).bold := p_bold;
    workbook.fonts( t_ind ).rgb := p_rgb;
    return t_ind;
  end;
--
  function get_fill
    ( p_patternType varchar2
    , p_fgRGB varchar2 := null
    )
  return pls_integer
  is
    t_ind pls_integer;
  begin
    if workbook.fills.count() > 0
    then
      for f in 0 .. workbook.fills.count() - 1
      loop
        if (   workbook.fills( f ).patternType = p_patternType
           and nvl( workbook.fills( f ).fgRGB, 'x' ) = nvl( upper( p_fgRGB ), 'x' )
           )
        then
          return f;
        end if;
      end loop;
    end if;
    t_ind := workbook.fills.count();
    workbook.fills( t_ind ).patternType := p_patternType;
    workbook.fills( t_ind ).fgRGB := upper( p_fgRGB );
    return t_ind;
  end;
--
  function get_border
    ( p_top varchar2 := 'thin'
    , p_bottom varchar2 := 'thin'
    , p_left varchar2 := 'thin'
    , p_right varchar2 := 'thin'
    )
  return pls_integer
  is
    t_ind pls_integer;
  begin
    if workbook.borders.count() > 0
    then
      for b in 0 .. workbook.borders.count() - 1
      loop
        if (   nvl( workbook.borders( b ).top, 'x' ) = nvl( p_top, 'x' )
           and nvl( workbook.borders( b ).bottom, 'x' ) = nvl( p_bottom, 'x' )
           and nvl( workbook.borders( b ).left, 'x' ) = nvl( p_left, 'x' )
           and nvl( workbook.borders( b ).right, 'x' ) = nvl( p_right, 'x' )
           )
        then
          return b;
        end if;
      end loop;
    end if;
    t_ind := workbook.borders.count();
    workbook.borders( t_ind ).top := p_top;
    workbook.borders( t_ind ).bottom := p_bottom;
    workbook.borders( t_ind ).left := p_left;
    workbook.borders( t_ind ).right := p_right;
    return t_ind;
  end;
--
  function get_alignment
    ( p_vertical varchar2 := null
    , p_horizontal varchar2 := null
    , p_wrapText boolean := null
    )
  return tp_alignment
  is
    t_rv tp_alignment;
  begin
    t_rv.vertical := p_vertical;
    t_rv.horizontal := p_horizontal;
    t_rv.wrapText := p_wrapText;
    return t_rv;
  end;
--
  function get_XfId
    ( p_sheet pls_integer
    , p_col pls_integer
    , p_row pls_integer
    , p_numFmtId pls_integer := null
    , p_fontId pls_integer := null
    , p_fillId pls_integer := null
    , p_borderId pls_integer := null
    , p_alignment tp_alignment := null
    )
  return varchar2
  is
    t_cnt pls_integer;
    t_XfId pls_integer;
    t_XF tp_XF_fmt;
    t_col_XF tp_XF_fmt;
    t_row_XF tp_XF_fmt;
  begin
    if workbook.sheets( p_sheet ).col_fmts.exists( p_col )
    then
      t_col_XF := workbook.sheets( p_sheet ).col_fmts( p_col );
    end if;
    if workbook.sheets( p_sheet ).row_fmts.exists( p_row )
    then
      t_row_XF := workbook.sheets( p_sheet ).row_fmts( p_row );
    end if;
    t_XF.numFmtId := coalesce( p_numFmtId, t_col_XF.numFmtId, t_row_XF.numFmtId, 0 );
    t_XF.fontId := coalesce( p_fontId, t_col_XF.fontId, t_row_XF.fontId, 0 );
    t_XF.fillId := coalesce( p_fillId, t_col_XF.fillId, t_row_XF.fillId, 0 );
    t_XF.borderId := coalesce( p_borderId, t_col_XF.borderId, t_row_XF.borderId, 0 );
    t_XF.alignment := coalesce( p_alignment, t_col_XF.alignment, t_row_XF.alignment );
    if (   t_XF.numFmtId + t_XF.fontId + t_XF.fillId + t_XF.borderId = 0
       and t_XF.alignment.vertical is null
       and t_XF.alignment.horizontal is null
       and not nvl( t_XF.alignment.wrapText, false )
       )
    then
      return '';
    end if;
    if t_XF.numFmtId > 0
    then
      set_col_width( p_sheet, p_col, workbook.numFmts( workbook.numFmtIndexes( t_XF.numFmtId ) ).formatCode );
    end if;
    t_cnt := workbook.cellXfs.count();
    for i in 1 .. t_cnt
    loop
      if (   workbook.cellXfs( i ).numFmtId = t_XF.numFmtId
         and workbook.cellXfs( i ).fontId = t_XF.fontId
         and workbook.cellXfs( i ).fillId = t_XF.fillId
         and workbook.cellXfs( i ).borderId = t_XF.borderId
         and nvl( workbook.cellXfs( i ).alignment.vertical, 'x' ) = nvl( t_XF.alignment.vertical, 'x' )
         and nvl( workbook.cellXfs( i ).alignment.horizontal, 'x' ) = nvl( t_XF.alignment.horizontal, 'x' )
         and nvl( workbook.cellXfs( i ).alignment.wrapText, false ) = nvl( t_XF.alignment.wrapText, false )
         )
      then
        t_XfId := i;
        exit;
      end if;
    end loop;
    if t_XfId is null
    then
      t_cnt := t_cnt + 1;
      t_XfId := t_cnt;
      workbook.cellXfs( t_cnt ) := t_XF;
    end if;
    return 's="' || t_XfId || '"';
  end;
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
    )
  is
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).value := p_value;
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).style := null;
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).style := get_XfId( t_sheet, p_col, p_row, p_numFmtId, p_fontId, p_fillId, p_borderId, p_alignment );
  end;
--
  function add_string( p_string varchar2 )
  return pls_integer
  is
    t_cnt pls_integer;
  begin
    if workbook.strings.exists( p_string )
    then
      t_cnt := workbook.strings( p_string );
    else
      t_cnt := workbook.strings.count();  
      workbook.str_ind( t_cnt ) := p_string;
      workbook.strings( nvl( p_string, '' ) ) := t_cnt;
    end if;
    workbook.str_cnt := workbook.str_cnt + 1;
    return t_cnt;
  end;
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
    )
  is
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
    t_alignment tp_alignment := p_alignment;
  begin
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).value := add_string( p_value );
    if t_alignment.wrapText is null and instr( p_value, chr(13) ) > 0
    then
      t_alignment.wrapText := true;
    end if;
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).style := 't="s" ' || get_XfId( t_sheet, p_col, p_row, p_numFmtId, p_fontId, p_fillId, p_borderId, t_alignment );
  end;
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
    )
  is
    t_numFmtId pls_integer := p_numFmtId;
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).value := p_value - to_date('01-01-1904','DD-MM-YYYY');
    if t_numFmtId is null
       and not (   workbook.sheets( t_sheet ).col_fmts.exists( p_col )
               and workbook.sheets( t_sheet ).col_fmts( p_col ).numFmtId is not null
               )
       and not (   workbook.sheets( t_sheet ).row_fmts.exists( p_row )
               and workbook.sheets( t_sheet ).row_fmts( p_row ).numFmtId is not null
               )
    then
      t_numFmtId := get_numFmt( 'dd/mm/yyyy' );
    end if;
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).style := get_XfId( t_sheet, p_col, p_row, t_numFmtId, p_fontId, p_fillId, p_borderId, p_alignment );
  end;
--
  procedure hyperlink
    ( p_col pls_integer
    , p_row pls_integer
    , p_url varchar2
    , p_value varchar2 := null
    , p_sheet pls_integer := null
    )
  is
    t_ind pls_integer;
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).value := add_string( nvl( p_value, p_url ) );
    workbook.sheets( t_sheet ).rows( p_row )( p_col ).style := 't="s" ' || get_XfId( t_sheet, p_col, p_row, '', get_font( 'Calibri', p_theme => 10, p_underline => true ) );
    t_ind := workbook.sheets( t_sheet ).hyperlinks.count() + 1;
    workbook.sheets( t_sheet ).hyperlinks( t_ind ).cell := alfan_col( p_col ) || p_row;
    workbook.sheets( t_sheet ).hyperlinks( t_ind ).url := p_url;
  end;
--
  procedure comment
    ( p_col pls_integer
    , p_row pls_integer
    , p_text varchar2
    , p_author varchar2 := null
    , p_width pls_integer := 150
    , p_height pls_integer := 100
    , p_sheet pls_integer := null
    )
  is
    t_ind pls_integer;
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    t_ind := workbook.sheets( t_sheet ).comments.count() + 1;
    workbook.sheets( t_sheet ).comments( t_ind ).row := p_row;
    workbook.sheets( t_sheet ).comments( t_ind ).column := p_col;
    workbook.sheets( t_sheet ).comments( t_ind ).text := dbms_xmlgen.convert( p_text );
    workbook.sheets( t_sheet ).comments( t_ind ).author := dbms_xmlgen.convert( p_author );
    workbook.sheets( t_sheet ).comments( t_ind ).width := p_width;
    workbook.sheets( t_sheet ).comments( t_ind ).height := p_height;
  end;
--
  procedure mergecells
    ( p_tl_col pls_integer -- top left
    , p_tl_row pls_integer
    , p_br_col pls_integer -- bottom right
    , p_br_row pls_integer
    , p_sheet pls_integer := null
    )
  is
    t_ind pls_integer;
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    t_ind := workbook.sheets( t_sheet ).mergecells.count() + 1;
    workbook.sheets( t_sheet ).mergecells( t_ind ) := alfan_col( p_tl_col ) || p_tl_row || ':' || alfan_col( p_br_col ) || p_br_row;
  end;
--
  procedure add_validation
    ( p_type varchar2
    , p_sqref varchar2
    , p_style varchar2 := 'stop' -- stop, warning, information
    , p_formula1 varchar2 := null
    , p_formula2 varchar2 := null
    , p_title varchar2 := null
    , p_prompt varchar := null
    , p_show_error boolean := false
    , p_error_title varchar2 := null
    , p_error_txt varchar2 := null
    , p_sheet pls_integer := null
    )
  is
    t_ind pls_integer;
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    t_ind := workbook.sheets( t_sheet ).validations.count() + 1;
    workbook.sheets( t_sheet ).validations( t_ind ).type := p_type;
    workbook.sheets( t_sheet ).validations( t_ind ).errorstyle := p_style;
    workbook.sheets( t_sheet ).validations( t_ind ).sqref := p_sqref;
    workbook.sheets( t_sheet ).validations( t_ind ).formula1 := p_formula1;
    workbook.sheets( t_sheet ).validations( t_ind ).error_title := p_error_title;
    workbook.sheets( t_sheet ).validations( t_ind ).error_txt := p_error_txt;
    workbook.sheets( t_sheet ).validations( t_ind ).title := p_title;
    workbook.sheets( t_sheet ).validations( t_ind ).prompt := p_prompt;
    workbook.sheets( t_sheet ).validations( t_ind ).showerrormessage := p_show_error;
  end;
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
    )
  is
  begin
    add_validation( 'list'
                  , alfan_col( p_sqref_col ) || p_sqref_row
                  , p_style => lower( p_style )
                  , p_formula1 => '$' || alfan_col( p_tl_col ) || '$' ||  p_tl_row || ':$' || alfan_col( p_br_col ) || '$' || p_br_row 
                  , p_title => p_title
                  , p_prompt => p_prompt
                  , p_show_error => p_show_error
                  , p_error_title => p_error_title
                  , p_error_txt => p_error_txt
                  , p_sheet => p_sheet
                  ); 
  end;
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
    )
  is
  begin
    add_validation( 'list'
                  , alfan_col( p_sqref_col ) || p_sqref_row
                  , p_style => lower( p_style )
                  , p_formula1 => p_defined_name 
                  , p_title => p_title
                  , p_prompt => p_prompt
                  , p_show_error => p_show_error
                  , p_error_title => p_error_title
                  , p_error_txt => p_error_txt
                  , p_sheet => p_sheet
                  ); 
  end;
--
  procedure defined_name
    ( p_tl_col pls_integer -- top left
    , p_tl_row pls_integer
    , p_br_col pls_integer -- bottom right
    , p_br_row pls_integer
    , p_name varchar2
    , p_sheet pls_integer := null
    , p_localsheet pls_integer := null
    )
  is
    t_ind pls_integer;
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    t_ind := workbook.defined_names.count() + 1;
    workbook.defined_names( t_ind ).name := p_name;
    workbook.defined_names( t_ind ).ref := 'Sheet' || t_sheet || '!$' || alfan_col( p_tl_col ) || '$' ||  p_tl_row || ':$' || alfan_col( p_br_col ) || '$' || p_br_row;
    workbook.defined_names( t_ind ).sheet := p_localsheet;
  end;
--
  procedure set_column_width
    ( p_col pls_integer
    , p_width number
    , p_sheet pls_integer := null
    )
  is
  begin
    workbook.sheets( nvl( p_sheet, workbook.sheets.count() ) ).widths( p_col ) := p_width;
  end;
--
  procedure set_column
    ( p_col pls_integer
    , p_numFmtId pls_integer := null
    , p_fontId pls_integer := null
    , p_fillId pls_integer := null
    , p_borderId pls_integer := null
    , p_alignment tp_alignment := null
    , p_sheet pls_integer := null
    )
  is
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    workbook.sheets( t_sheet ).col_fmts( p_col ).numFmtId := p_numFmtId;
    workbook.sheets( t_sheet ).col_fmts( p_col ).fontId := p_fontId;
    workbook.sheets( t_sheet ).col_fmts( p_col ).fillId := p_fillId;
    workbook.sheets( t_sheet ).col_fmts( p_col ).borderId := p_borderId;
    workbook.sheets( t_sheet ).col_fmts( p_col ).alignment := p_alignment;
  end;
--
  procedure set_row
    ( p_row pls_integer
    , p_numFmtId pls_integer := null
    , p_fontId pls_integer := null
    , p_fillId pls_integer := null
    , p_borderId pls_integer := null
    , p_alignment tp_alignment := null
    , p_sheet pls_integer := null
    )
  is
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    workbook.sheets( t_sheet ).row_fmts( p_row ).numFmtId := p_numFmtId;
    workbook.sheets( t_sheet ).row_fmts( p_row ).fontId := p_fontId;
    workbook.sheets( t_sheet ).row_fmts( p_row ).fillId := p_fillId;
    workbook.sheets( t_sheet ).row_fmts( p_row ).borderId := p_borderId;
    workbook.sheets( t_sheet ).row_fmts( p_row ).alignment := p_alignment;
  end;
--
  procedure freeze_rows
    ( p_nr_rows pls_integer := 1
    , p_sheet pls_integer := null
    )
  is
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    workbook.sheets( t_sheet ).freeze_cols := null;
    workbook.sheets( t_sheet ).freeze_rows := p_nr_rows;
  end;
--
  procedure freeze_cols
    ( p_nr_cols pls_integer := 1
    , p_sheet pls_integer := null
    )
  is
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    workbook.sheets( t_sheet ).freeze_rows := null;
    workbook.sheets( t_sheet ).freeze_cols := p_nr_cols;
  end;
--
  procedure freeze_pane
    ( p_col pls_integer
    , p_row pls_integer
    , p_sheet pls_integer := null
    )
  is
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    workbook.sheets( t_sheet ).freeze_rows := p_row;
    workbook.sheets( t_sheet ).freeze_cols := p_col;
  end;
--
  procedure set_autofilter
    ( p_column_start pls_integer := null
    , p_column_end pls_integer := null
    , p_row_start pls_integer := null
    , p_row_end pls_integer := null
    , p_sheet pls_integer := null
    )
  is
    t_ind pls_integer;
    t_sheet pls_integer := nvl( p_sheet, workbook.sheets.count() );
  begin
    t_ind := 1;
    workbook.sheets( t_sheet ).autofilters( t_ind ).column_start := p_column_start;
    workbook.sheets( t_sheet ).autofilters( t_ind ).column_end := p_column_end;
    workbook.sheets( t_sheet ).autofilters( t_ind ).row_start := p_row_start;
    workbook.sheets( t_sheet ).autofilters( t_ind ).row_end := p_row_end;
    defined_name
      ( p_column_start
      , p_row_start
      , p_column_end
      , p_row_end
      , '_xlnm._FilterDatabase'
      , t_sheet
      , t_sheet - 1
      );
  end;
--
/*
  procedure add1xml
    ( p_excel in out nocopy blob
    , p_filename varchar2
    , p_xml clob
    )
  is
    t_tmp blob;
    c_step constant number := 24396;
  begin
    dbms_lob.createtemporary( t_tmp, true );
    for i in 0 .. trunc( length( p_xml ) / c_step )
    loop
      dbms_lob.append( t_tmp, utl_i18n.string_to_raw( substr( p_xml, i * c_step + 1, c_step ), 'AL32UTF8' ) );
    end loop;
    add1file( p_excel, p_filename, t_tmp );
    dbms_lob.freetemporary( t_tmp );
  end;
*/
--
  procedure add1xml
    ( p_excel in out nocopy blob
    , p_filename varchar2
    , p_xml clob
    )
  is
    t_tmp blob;
    dest_offset integer := 1;
    src_offset integer := 1;
    lang_context integer;
    warning integer;
  begin
    lang_context := dbms_lob.DEFAULT_LANG_CTX;
    dbms_lob.createtemporary( t_tmp, true );
    dbms_lob.converttoblob
      ( t_tmp
      , p_xml
      , dbms_lob.lobmaxsize
      , dest_offset
      , src_offset
      ,  nls_charset_id( 'AL32UTF8'  ) 
      , lang_context
      , warning
      );
    add1file( p_excel, p_filename, t_tmp );
    dbms_lob.freetemporary( t_tmp );
  end;
--
  function finish
  return blob
  is
    t_excel blob;
    t_xxx clob;
    t_tmp varchar2(32767 char);
    t_str varchar2(32767 char);
    t_c number;
    t_h number;
    t_w number;
    t_cw number;
    t_cell varchar2(1000 char);
    t_row_ind pls_integer;
    t_col_min pls_integer;
    t_col_max pls_integer;
    t_col_ind pls_integer;
    t_len pls_integer;
ts timestamp := systimestamp;
  begin
    dbms_lob.createtemporary( t_excel, true );
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Default Extension="vml" ContentType="application/vnd.openxmlformats-officedocument.vmlDrawing"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>';
    for s in 1 .. workbook.sheets.count()
    loop
      t_xxx := t_xxx || '
<Override PartName="/xl/worksheets/sheet' || s || '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>';
    end loop;
    t_xxx := t_xxx || '
<Override PartName="/xl/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>';
    for s in 1 .. workbook.sheets.count()
    loop
      if workbook.sheets( s ).comments.count() > 0
      then
        t_xxx := t_xxx || '
<Override PartName="/xl/comments' || s || '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml"/>';
      end if;
    end loop;
    t_xxx := t_xxx || '
</Types>';
    add1xml( t_excel, '[Content_Types].xml', t_xxx );
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:creator>' || sys_context( 'userenv', 'os_user' ) || '</dc:creator>
<cp:lastModifiedBy>' || sys_context( 'userenv', 'os_user' ) || '</cp:lastModifiedBy>
<dcterms:created xsi:type="dcterms:W3CDTF">' || to_char( current_timestamp, 'yyyy-mm-dd"T"hh24:mi:ssTZH:TZM' ) || '</dcterms:created>
<dcterms:modified xsi:type="dcterms:W3CDTF">' || to_char( current_timestamp, 'yyyy-mm-dd"T"hh24:mi:ssTZH:TZM' ) || '</dcterms:modified>
</cp:coreProperties>';
    add1xml( t_excel, 'docProps/core.xml', t_xxx );
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
<Application>Microsoft Excel</Application>
<DocSecurity>0</DocSecurity>
<ScaleCrop>false</ScaleCrop>
<HeadingPairs>
<vt:vector size="2" baseType="variant">
<vt:variant>
<vt:lpstr>Worksheets</vt:lpstr>
</vt:variant>
<vt:variant>
<vt:i4>' || workbook.sheets.count() || '</vt:i4>
</vt:variant>
</vt:vector>
</HeadingPairs>
<TitlesOfParts>
<vt:vector size="' || workbook.sheets.count() || '" baseType="lpstr">';
    for s in 1 .. workbook.sheets.count()
    loop
      t_xxx := t_xxx || '
<vt:lpstr>' || workbook.sheets( s ).name || '</vt:lpstr>';
    end loop;
    t_xxx := t_xxx || '</vt:vector>
</TitlesOfParts>
<LinksUpToDate>false</LinksUpToDate>
<SharedDoc>false</SharedDoc>
<HyperlinksChanged>false</HyperlinksChanged>
<AppVersion>14.0300</AppVersion>
</Properties>';
    add1xml( t_excel, 'docProps/app.xml', t_xxx );
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>';
    add1xml( t_excel, '_rels/.rels', t_xxx );
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">';
    if workbook.numFmts.count() > 0
    then
      t_xxx := t_xxx || '<numFmts count="' || workbook.numFmts.count() || '">';
      for n in 1 .. workbook.numFmts.count()
      loop
        t_xxx := t_xxx || '<numFmt numFmtId="' || workbook.numFmts( n ).numFmtId || '" formatCode="' || workbook.numFmts( n ).formatCode || '"/>';
      end loop;
      t_xxx := t_xxx || '</numFmts>';
    end if;
    t_xxx := t_xxx || '<fonts count="' || workbook.fonts.count() || '" x14ac:knownFonts="1">';
    for f in 0 .. workbook.fonts.count() - 1
    loop
      t_xxx := t_xxx || '<font>' || 
        case when workbook.fonts( f ).bold then '<b/>' end ||
        case when workbook.fonts( f ).italic then '<i/>' end ||
        case when workbook.fonts( f ).underline then '<u/>' end ||
'<sz val="' || to_char( workbook.fonts( f ).fontsize, 'TM9', 'NLS_NUMERIC_CHARACTERS=.,' )  || '"/>
<color ' || case when workbook.fonts( f ).rgb is not null
              then 'rgb="' || workbook.fonts( f ).rgb
              else 'theme="' || workbook.fonts( f ).theme
            end || '"/>
<name val="' || workbook.fonts( f ).name || '"/>
<family val="' || workbook.fonts( f ).family || '"/>
<scheme val="none"/>
</font>';
    end loop;
    t_xxx := t_xxx || '</fonts>
<fills count="' || workbook.fills.count() || '">';
    for f in 0 .. workbook.fills.count() - 1
    loop
      t_xxx := t_xxx || '<fill><patternFill patternType="' || workbook.fills( f ).patternType || '">' ||
         case when workbook.fills( f ).fgRGB is not null then '<fgColor rgb="' || workbook.fills( f ).fgRGB || '"/>' end ||
         '</patternFill></fill>';
    end loop;
    t_xxx := t_xxx || '</fills>
<borders count="' || workbook.borders.count() || '">';
    for b in 0 .. workbook.borders.count() - 1
    loop
      t_xxx := t_xxx || '<border>' ||
         case when workbook.borders( b ).left   is null then '<left/>'   else '<left style="'   || workbook.borders( b ).left   || '"/>' end ||
         case when workbook.borders( b ).right  is null then '<right/>'  else '<right style="'  || workbook.borders( b ).right  || '"/>' end ||
         case when workbook.borders( b ).top    is null then '<top/>'    else '<top style="'    || workbook.borders( b ).top    || '"/>' end ||
         case when workbook.borders( b ).bottom is null then '<bottom/>' else '<bottom style="' || workbook.borders( b ).bottom || '"/>' end ||
         '</border>';
    end loop;
    t_xxx := t_xxx || '</borders>
<cellStyleXfs count="1">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
</cellStyleXfs>
<cellXfs count="' || ( workbook.cellXfs.count() + 1 ) || '">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>';
    for x in 1 .. workbook.cellXfs.count()
    loop
      t_xxx := t_xxx || '<xf numFmtId="' || workbook.cellXfs( x ).numFmtId || '" fontId="' || workbook.cellXfs( x ).fontId || '" fillId="' || workbook.cellXfs( x ).fillId || '" borderId="' || workbook.cellXfs( x ).borderId || '">';
      if (  workbook.cellXfs( x ).alignment.horizontal is not null
         or workbook.cellXfs( x ).alignment.vertical is not null
         or workbook.cellXfs( x ).alignment.wrapText
         )
      then
        t_xxx := t_xxx || '<alignment' ||
          case when workbook.cellXfs( x ).alignment.horizontal is not null then ' horizontal="' || workbook.cellXfs( x ).alignment.horizontal || '"' end ||
          case when workbook.cellXfs( x ).alignment.vertical is not null then ' vertical="' || workbook.cellXfs( x ).alignment.vertical || '"' end ||
          case when workbook.cellXfs( x ).alignment.wrapText then ' wrapText="true"' end || '/>';
      end if;
      t_xxx := t_xxx || '</xf>';
    end loop;
    t_xxx := t_xxx || '</cellXfs>
<cellStyles count="1">
<cellStyle name="Normal" xfId="0" builtinId="0"/>
</cellStyles>
<dxfs count="0"/>
<tableStyles count="0" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>
<extLst>
<ext uri="{EB79DEF2-80B8-43e5-95BD-54CBDDF9020C}" xmlns:x14="http://schemas.microsoft.com/office/spreadsheetml/2009/9/main">
<x14:slicerStyles defaultSlicerStyle="SlicerStyleLight1"/>
</ext>
</extLst>
</styleSheet>';
    add1xml( t_excel, 'xl/styles.xml', t_xxx );
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<fileVersion appName="xl" lastEdited="5" lowestEdited="5" rupBuild="9302"/>
<workbookPr date1904="true" defaultThemeVersion="124226"/>
<bookViews>
<workbookView xWindow="120" yWindow="45" windowWidth="19155" windowHeight="4935"/>
</bookViews>
<sheets>';
    for s in 1 .. workbook.sheets.count()
    loop
      t_xxx := t_xxx || '
<sheet name="' || workbook.sheets( s ).name || '" sheetId="' || s || '" r:id="rId' || ( 9 + s ) || '"/>';
    end loop;
    t_xxx := t_xxx || '</sheets>';
    if workbook.defined_names.count() > 0
    then
      t_xxx := t_xxx || '<definedNames>';
      for s in 1 .. workbook.defined_names.count()
      loop
        t_xxx := t_xxx || '
<definedName name="' || workbook.defined_names( s ).name || '"' ||
            case when workbook.defined_names( s ).sheet is not null then ' localSheetId="' || to_char( workbook.defined_names( s ).sheet ) || '"' end ||
            '>' || workbook.defined_names( s ).ref || '</definedName>';
      end loop;
      t_xxx := t_xxx || '</definedNames>';
    end if;
    t_xxx := t_xxx || '<calcPr calcId="144525"/></workbook>';
    add1xml( t_excel, 'xl/workbook.xml', t_xxx );
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
<a:themeElements>
<a:clrScheme name="Office">
<a:dk1>
<a:sysClr val="windowText" lastClr="000000"/>
</a:dk1>
<a:lt1>
<a:sysClr val="window" lastClr="FFFFFF"/>
</a:lt1>
<a:dk2>
<a:srgbClr val="1F497D"/>
</a:dk2>
<a:lt2>
<a:srgbClr val="EEECE1"/>
</a:lt2>
<a:accent1>
<a:srgbClr val="4F81BD"/>
</a:accent1>
<a:accent2>
<a:srgbClr val="C0504D"/>
</a:accent2>
<a:accent3>
<a:srgbClr val="9BBB59"/>
</a:accent3>
<a:accent4>
<a:srgbClr val="8064A2"/>
</a:accent4>
<a:accent5>
<a:srgbClr val="4BACC6"/>
</a:accent5>
<a:accent6>
<a:srgbClr val="F79646"/>
</a:accent6>
<a:hlink>
<a:srgbClr val="0000FF"/>
</a:hlink>
<a:folHlink>
<a:srgbClr val="800080"/>
</a:folHlink>
</a:clrScheme>
<a:fontScheme name="Office">
<a:majorFont>
<a:latin typeface="Cambria"/>
<a:ea typeface=""/>
<a:cs typeface=""/>
<a:font script="Jpan" typeface="ＭＳ Ｐゴシック"/>
<a:font script="Hang" typeface="맑은 고딕"/>
<a:font script="Hans" typeface="宋体"/>
<a:font script="Hant" typeface="新細明體"/>
<a:font script="Arab" typeface="Times New Roman"/>
<a:font script="Hebr" typeface="Times New Roman"/>
<a:font script="Thai" typeface="Tahoma"/>
<a:font script="Ethi" typeface="Nyala"/>
<a:font script="Beng" typeface="Vrinda"/>
<a:font script="Gujr" typeface="Shruti"/>
<a:font script="Khmr" typeface="MoolBoran"/>
<a:font script="Knda" typeface="Tunga"/>
<a:font script="Guru" typeface="Raavi"/>
<a:font script="Cans" typeface="Euphemia"/>
<a:font script="Cher" typeface="Plantagenet Cherokee"/>
<a:font script="Yiii" typeface="Microsoft Yi Baiti"/>
<a:font script="Tibt" typeface="Microsoft Himalaya"/>
<a:font script="Thaa" typeface="MV Boli"/>
<a:font script="Deva" typeface="Mangal"/>
<a:font script="Telu" typeface="Gautami"/>
<a:font script="Taml" typeface="Latha"/>
<a:font script="Syrc" typeface="Estrangelo Edessa"/>
<a:font script="Orya" typeface="Kalinga"/>
<a:font script="Mlym" typeface="Kartika"/>
<a:font script="Laoo" typeface="DokChampa"/>
<a:font script="Sinh" typeface="Iskoola Pota"/>
<a:font script="Mong" typeface="Mongolian Baiti"/>
<a:font script="Viet" typeface="Times New Roman"/>
<a:font script="Uigh" typeface="Microsoft Uighur"/>
<a:font script="Geor" typeface="Sylfaen"/>
</a:majorFont>
<a:minorFont>
<a:latin typeface="Calibri"/>
<a:ea typeface=""/>
<a:cs typeface=""/>
<a:font script="Jpan" typeface="ＭＳ Ｐゴシック"/>
<a:font script="Hang" typeface="맑은 고딕"/>
<a:font script="Hans" typeface="宋体"/>
<a:font script="Hant" typeface="新細明體"/>
<a:font script="Arab" typeface="Arial"/>
<a:font script="Hebr" typeface="Arial"/>
<a:font script="Thai" typeface="Tahoma"/>
<a:font script="Ethi" typeface="Nyala"/>
<a:font script="Beng" typeface="Vrinda"/>
<a:font script="Gujr" typeface="Shruti"/>
<a:font script="Khmr" typeface="DaunPenh"/>
<a:font script="Knda" typeface="Tunga"/>
<a:font script="Guru" typeface="Raavi"/>
<a:font script="Cans" typeface="Euphemia"/>
<a:font script="Cher" typeface="Plantagenet Cherokee"/>
<a:font script="Yiii" typeface="Microsoft Yi Baiti"/>
<a:font script="Tibt" typeface="Microsoft Himalaya"/>
<a:font script="Thaa" typeface="MV Boli"/>
<a:font script="Deva" typeface="Mangal"/>
<a:font script="Telu" typeface="Gautami"/>
<a:font script="Taml" typeface="Latha"/>
<a:font script="Syrc" typeface="Estrangelo Edessa"/>
<a:font script="Orya" typeface="Kalinga"/>
<a:font script="Mlym" typeface="Kartika"/>
<a:font script="Laoo" typeface="DokChampa"/>
<a:font script="Sinh" typeface="Iskoola Pota"/>
<a:font script="Mong" typeface="Mongolian Baiti"/>
<a:font script="Viet" typeface="Arial"/>
<a:font script="Uigh" typeface="Microsoft Uighur"/>
<a:font script="Geor" typeface="Sylfaen"/>
</a:minorFont>
</a:fontScheme>
<a:fmtScheme name="Office">
<a:fillStyleLst>
<a:solidFill>
<a:schemeClr val="phClr"/>
</a:solidFill>
<a:gradFill rotWithShape="1">
<a:gsLst>
<a:gs pos="0">
<a:schemeClr val="phClr">
<a:tint val="50000"/>
<a:satMod val="300000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="35000">
<a:schemeClr val="phClr">
<a:tint val="37000"/>
<a:satMod val="300000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="100000">
<a:schemeClr val="phClr">
<a:tint val="15000"/>
<a:satMod val="350000"/>
</a:schemeClr>
</a:gs>
</a:gsLst>
<a:lin ang="16200000" scaled="1"/>
</a:gradFill>
<a:gradFill rotWithShape="1">
<a:gsLst>
<a:gs pos="0">
<a:schemeClr val="phClr">
<a:shade val="51000"/>
<a:satMod val="130000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="80000">
<a:schemeClr val="phClr">
<a:shade val="93000"/>
<a:satMod val="130000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="100000">
<a:schemeClr val="phClr">
<a:shade val="94000"/>
<a:satMod val="135000"/>
</a:schemeClr>
</a:gs>
</a:gsLst>
<a:lin ang="16200000" scaled="0"/>
</a:gradFill>
</a:fillStyleLst>
<a:lnStyleLst>
<a:ln w="9525" cap="flat" cmpd="sng" algn="ctr">
<a:solidFill>
<a:schemeClr val="phClr">
<a:shade val="95000"/>
<a:satMod val="105000"/>
</a:schemeClr>
</a:solidFill>
<a:prstDash val="solid"/>
</a:ln>
<a:ln w="25400" cap="flat" cmpd="sng" algn="ctr">
<a:solidFill>
<a:schemeClr val="phClr"/>
</a:solidFill>
<a:prstDash val="solid"/>
</a:ln>
<a:ln w="38100" cap="flat" cmpd="sng" algn="ctr">
<a:solidFill>
<a:schemeClr val="phClr"/>
</a:solidFill>
<a:prstDash val="solid"/>
</a:ln>
</a:lnStyleLst>
<a:effectStyleLst>
<a:effectStyle>
<a:effectLst>
<a:outerShdw blurRad="40000" dist="20000" dir="5400000" rotWithShape="0">
<a:srgbClr val="000000">
<a:alpha val="38000"/>
</a:srgbClr>
</a:outerShdw>
</a:effectLst>
</a:effectStyle>
<a:effectStyle>
<a:effectLst>
<a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0">
<a:srgbClr val="000000">
<a:alpha val="35000"/>
</a:srgbClr>
</a:outerShdw>
</a:effectLst>
</a:effectStyle>
<a:effectStyle>
<a:effectLst>
<a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0">
<a:srgbClr val="000000">
<a:alpha val="35000"/>
</a:srgbClr>
</a:outerShdw>
</a:effectLst>
<a:scene3d>
<a:camera prst="orthographicFront">
<a:rot lat="0" lon="0" rev="0"/>
</a:camera>
<a:lightRig rig="threePt" dir="t">
<a:rot lat="0" lon="0" rev="1200000"/>
</a:lightRig>
</a:scene3d>
<a:sp3d>
<a:bevelT w="63500" h="25400"/>
</a:sp3d>
</a:effectStyle>
</a:effectStyleLst>
<a:bgFillStyleLst>
<a:solidFill>
<a:schemeClr val="phClr"/>
</a:solidFill>
<a:gradFill rotWithShape="1">
<a:gsLst>
<a:gs pos="0">
<a:schemeClr val="phClr">
<a:tint val="40000"/>
<a:satMod val="350000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="40000">
<a:schemeClr val="phClr">
<a:tint val="45000"/>
<a:shade val="99000"/>
<a:satMod val="350000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="100000">
<a:schemeClr val="phClr">
<a:shade val="20000"/>
<a:satMod val="255000"/>
</a:schemeClr>
</a:gs>
</a:gsLst>
<a:path path="circle">
<a:fillToRect l="50000" t="-80000" r="50000" b="180000"/>
</a:path>
</a:gradFill>
<a:gradFill rotWithShape="1">
<a:gsLst>
<a:gs pos="0">
<a:schemeClr val="phClr">
<a:tint val="80000"/>
<a:satMod val="300000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="100000">
<a:schemeClr val="phClr">
<a:shade val="30000"/>
<a:satMod val="200000"/>
</a:schemeClr>
</a:gs>
</a:gsLst>
<a:path path="circle">
<a:fillToRect l="50000" t="50000" r="50000" b="50000"/>
</a:path>
</a:gradFill>
</a:bgFillStyleLst>
</a:fmtScheme>
</a:themeElements>
<a:objectDefaults/>
<a:extraClrSchemeLst/>
</a:theme>';
    add1xml( t_excel, 'xl/theme/theme1.xml', t_xxx );
    for s in 1 .. workbook.sheets.count()
    loop
      t_col_min := 16384;
      t_col_max := 1;
      t_row_ind := workbook.sheets( s ).rows.first();
      while t_row_ind is not null
      loop
        t_col_min := least( t_col_min, workbook.sheets( s ).rows( t_row_ind ).first() );
        t_col_max := greatest( t_col_max, workbook.sheets( s ).rows( t_row_ind ).last() );
        t_row_ind := workbook.sheets( s ).rows.next( t_row_ind );
      end loop;
      t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:x14="http://schemas.microsoft.com/office/spreadsheetml/2009/9/main" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">
<dimension ref="' || alfan_col( t_col_min ) || workbook.sheets( s ).rows.first() || ':' || alfan_col( t_col_max ) || workbook.sheets( s ).rows.last() || '"/>
<sheetViews>
<sheetView' || case when s = 1 then ' tabSelected="1"' end || ' workbookViewId="0">';
      if workbook.sheets( s ).freeze_rows > 0 and workbook.sheets( s ).freeze_cols > 0
      then
        t_xxx := t_xxx || ( '<pane xSplit="' || workbook.sheets( s ).freeze_cols || '" '
                          || 'ySplit="' || workbook.sheets( s ).freeze_rows || '" '
                          || 'topLeftCell="' || alfan_col( workbook.sheets( s ).freeze_cols + 1 ) || ( workbook.sheets( s ).freeze_rows + 1 ) || '" '
                          || 'activePane="bottomLeft" state="frozen"/>'
                          );
      else
        if workbook.sheets( s ).freeze_rows > 0
        then
          t_xxx := t_xxx || '<pane ySplit="' || workbook.sheets( s ).freeze_rows || '" topLeftCell="A' || ( workbook.sheets( s ).freeze_rows + 1 ) || '" activePane="bottomLeft" state="frozen"/>';
        end if;
        if workbook.sheets( s ).freeze_cols > 0
        then
          t_xxx := t_xxx || '<pane xSplit="' || workbook.sheets( s ).freeze_cols || '" topLeftCell="' || alfan_col( workbook.sheets( s ).freeze_cols + 1 ) || '1" activePane="bottomLeft" state="frozen"/>';
        end if;
      end if;
      t_xxx := t_xxx || '</sheetView>
</sheetViews>
<sheetFormatPr defaultRowHeight="15" x14ac:dyDescent="0.25"/>';
      if workbook.sheets( s ).widths.count() > 0
      then
        t_xxx := t_xxx || '<cols>';
        t_col_ind := workbook.sheets( s ).widths.first();
        while t_col_ind is not null
        loop
          t_xxx := t_xxx ||
             '<col min="' || t_col_ind || '" max="' || t_col_ind || '" width="' || to_char( workbook.sheets( s ).widths( t_col_ind ), 'TM9', 'NLS_NUMERIC_CHARACTERS=.,' ) || '" customWidth="1"/>';
          t_col_ind := workbook.sheets( s ).widths.next( t_col_ind );
        end loop;
        t_xxx := t_xxx || '</cols>';
      end if;
      t_xxx := t_xxx || '<sheetData>';
      t_row_ind := workbook.sheets( s ).rows.first();
      t_tmp := null;
      while t_row_ind is not null
      loop
        t_tmp :=  t_tmp || '<row r="' || t_row_ind || '" spans="' || t_col_min || ':' || t_col_max || '">';
        t_len := length( t_tmp );
        t_col_ind := workbook.sheets( s ).rows( t_row_ind ).first();
        while t_col_ind is not null
        loop
          t_cell := '<c r="' || alfan_col( t_col_ind ) || t_row_ind || '"'
                 || ' ' || workbook.sheets( s ).rows( t_row_ind )( t_col_ind ).style
                 || '><v>'
                 || to_char( workbook.sheets( s ).rows( t_row_ind )( t_col_ind ).value, 'TM9', 'NLS_NUMERIC_CHARACTERS=.,' )
                 || '</v></c>';
          if t_len > 32000
          then
            dbms_lob.writeappend( t_xxx, t_len, t_tmp );
            t_tmp := null;
            t_len := 0;
          end if;
          t_tmp :=  t_tmp || t_cell;
          t_len := t_len + length( t_cell );
          t_col_ind := workbook.sheets( s ).rows( t_row_ind ).next( t_col_ind );
        end loop;
        t_tmp :=  t_tmp || '</row>';
        t_row_ind := workbook.sheets( s ).rows.next( t_row_ind );
      end loop;
      t_tmp :=  t_tmp || '</sheetData>';
      t_len := length( t_tmp );
      dbms_lob.writeappend( t_xxx, t_len, t_tmp );
      for a in 1 ..  workbook.sheets( s ).autofilters.count()
      loop
        t_xxx := t_xxx || '<autoFilter ref="' ||
            alfan_col( nvl( workbook.sheets( s ).autofilters( a ).column_start, t_col_min ) ) ||
            to_char( nvl( workbook.sheets( s ).autofilters( a ).row_start, workbook.sheets( s ).rows.first() )) || ':' ||
            alfan_col( coalesce( workbook.sheets( s ).autofilters( a ).column_end, workbook.sheets( s ).autofilters( a ).column_start, t_col_max ) ) ||
            to_char( nvl( workbook.sheets( s ).autofilters( a ).row_end, workbook.sheets( s ).rows.last() )) || '"/>';
      end loop;
      if workbook.sheets( s ).mergecells.count() > 0
      then
        t_xxx := t_xxx || '<mergeCells count="' || to_char( workbook.sheets( s ).mergecells.count() ) || '">';
        for m in 1 ..  workbook.sheets( s ).mergecells.count()
        loop
          t_xxx := t_xxx || '<mergeCell ref="' || workbook.sheets( s ).mergecells( m ) || '"/>';
        end loop;
        t_xxx := t_xxx || '</mergeCells>';
      end if;
--
      if workbook.sheets( s ).validations.count() > 0
      then
        t_xxx := t_xxx || '<dataValidations count="' || to_char( workbook.sheets( s ).validations.count() ) || '">';
        for m in 1 ..  workbook.sheets( s ).validations.count()
        loop
          t_xxx := t_xxx || '<dataValidation' ||
              ' type="' || workbook.sheets( s ).validations( m ).type || '"' ||
              ' errorStyle="' || workbook.sheets( s ).validations( m ).errorstyle || '"' ||
              ' allowBlank="' || case when nvl( workbook.sheets( s ).validations( m ).allowBlank, true ) then '1' else '0' end || '"' ||
              ' sqref="' || workbook.sheets( s ).validations( m ).sqref || '"';
          if workbook.sheets( s ).validations( m ).prompt is not null
          then
            t_xxx := t_xxx || ' showInputMessage="1" prompt="' || workbook.sheets( s ).validations( m ).prompt || '"';
            if workbook.sheets( s ).validations( m ).title is not null
            then
              t_xxx := t_xxx || ' promptTitle="' || workbook.sheets( s ).validations( m ).title || '"';
            end if;
          end if;
          if workbook.sheets( s ).validations( m ).showerrormessage
          then
            t_xxx := t_xxx || ' showErrorMessage="1"';
            if workbook.sheets( s ).validations( m ).error_title is not null
            then
              t_xxx := t_xxx || ' errorTitle="' || workbook.sheets( s ).validations( m ).error_title || '"';
            end if;
            if workbook.sheets( s ).validations( m ).error_txt is not null
            then
              t_xxx := t_xxx || ' error="' || workbook.sheets( s ).validations( m ).error_txt || '"';
            end if;
          end if;
          t_xxx := t_xxx || '>';
          if workbook.sheets( s ).validations( m ).formula1 is not null
          then
            t_xxx := t_xxx || '<formula1>' || workbook.sheets( s ).validations( m ).formula1 || '</formula1>';
          end if;
          if workbook.sheets( s ).validations( m ).formula2 is not null
          then
            t_xxx := t_xxx || '<formula2>' || workbook.sheets( s ).validations( m ).formula2 || '</formula2>';
          end if;
          t_xxx := t_xxx || '</dataValidation>';
        end loop;
        t_xxx := t_xxx || '</dataValidations>';
      end if;
--
      if workbook.sheets( s ).hyperlinks.count() > 0
      then
        t_xxx := t_xxx || '<hyperlinks>';
        for h in 1 ..  workbook.sheets( s ).hyperlinks.count()
        loop
          t_xxx := t_xxx || '<hyperlink ref="' || workbook.sheets( s ).hyperlinks( h ).cell || '" r:id="rId' || h || '"/>';
        end loop;
        t_xxx := t_xxx || '</hyperlinks>';
      end if;
      t_xxx := t_xxx || '<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>';
      if workbook.sheets( s ).comments.count() > 0
      then
        t_xxx := t_xxx || '<legacyDrawing r:id="rId' || to_char( workbook.sheets( s ).hyperlinks.count() + 1 ) || '"/>';
      end if;
--
      t_xxx := t_xxx || '</worksheet>';
      add1xml( t_excel, 'xl/worksheets/sheet' || s || '.xml', t_xxx );
      if workbook.sheets( s ).hyperlinks.count() > 0 or workbook.sheets( s ).comments.count() > 0
      then
        t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';
        if workbook.sheets( s ).comments.count() > 0
        then
          t_xxx := t_xxx || '<Relationship Id="rId' || ( workbook.sheets( s ).hyperlinks.count() + 2 ) || '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments" Target="../comments' || s || '.xml"/>';
          t_xxx := t_xxx || '<Relationship Id="rId' || ( workbook.sheets( s ).hyperlinks.count() + 1 ) || '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/vmlDrawing" Target="../drawings/vmlDrawing' || s || '.vml"/>';
        end if;
        for h in 1 ..  workbook.sheets( s ).hyperlinks.count()
        loop
          t_xxx := t_xxx || '<Relationship Id="rId' || h || '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="' || workbook.sheets( s ).hyperlinks( h ).url || '" TargetMode="External"/>';
        end loop;
        t_xxx := t_xxx || '</Relationships>';
        add1xml( t_excel, 'xl/worksheets/_rels/sheet' || s || '.xml.rels', t_xxx );
      end if;
--
      if workbook.sheets( s ).comments.count() > 0
      then
        declare
          cnt pls_integer;
          author_ind tp_author;
--          t_col_ind := workbook.sheets( s ).widths.next( t_col_ind );
        begin
          authors.delete();
          for c in 1 .. workbook.sheets( s ).comments.count()
          loop
            authors( workbook.sheets( s ).comments( c ).author ) := 0;
          end loop;
          t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<comments xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<authors>';
          cnt := 0;
          author_ind := authors.first();
          while author_ind is not null or authors.next( author_ind ) is not null
          loop
            authors( author_ind ) := cnt;
            t_xxx := t_xxx || '<author>' || author_ind || '</author>';
            cnt := cnt + 1;
            author_ind := authors.next( author_ind );
          end loop;
        end;
        t_xxx := t_xxx || '</authors><commentList>';
        for c in 1 .. workbook.sheets( s ).comments.count()
        loop
          t_xxx := t_xxx || '<comment ref="' || alfan_col( workbook.sheets( s ).comments( c ).column ) ||
             to_char( workbook.sheets( s ).comments( c ).row || '" authorId="' || authors( workbook.sheets( s ).comments( c ).author ) ) || '">
<text>';
          if workbook.sheets( s ).comments( c ).author is not null
          then
            t_xxx := t_xxx || '<r><rPr><b/><sz val="9"/><color indexed="81"/><rFont val="Tahoma"/><charset val="1"/></rPr><t xml:space="preserve">' ||
               workbook.sheets( s ).comments( c ).author || ':</t></r>';
          end if;
          t_xxx := t_xxx || '<r><rPr><sz val="9"/><color indexed="81"/><rFont val="Tahoma"/><charset val="1"/></rPr><t xml:space="preserve">' ||
             case when workbook.sheets( s ).comments( c ).author is not null then '
' end || workbook.sheets( s ).comments( c ).text || '</t></r></text></comment>';
        end loop;
        t_xxx := t_xxx || '</commentList></comments>';
        add1xml( t_excel, 'xl/comments' || s || '.xml', t_xxx );
        t_xxx := '<xml xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel">
<o:shapelayout v:ext="edit"><o:idmap v:ext="edit" data="2"/></o:shapelayout>
<v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202" path="m,l,21600r21600,l21600,xe"><v:stroke joinstyle="miter"/><v:path gradientshapeok="t" o:connecttype="rect"/></v:shapetype>';
        for c in 1 .. workbook.sheets( s ).comments.count()
        loop
          t_xxx := t_xxx || '<v:shape id="_x0000_s' || to_char( c ) || '" type="#_x0000_t202"
style="position:absolute;margin-left:35.25pt;margin-top:3pt;z-index:' || to_char( c ) || ';visibility:hidden;" fillcolor="#ffffe1" o:insetmode="auto">
<v:fill color2="#ffffe1"/><v:shadow on="t" color="black" obscured="t"/><v:path o:connecttype="none"/>
<v:textbox style="mso-direction-alt:auto"><div style="text-align:left"></div></v:textbox>
<x:ClientData ObjectType="Note"><x:MoveWithCells/><x:SizeWithCells/>';
          t_w := workbook.sheets( s ).comments( c ).width;
          t_c := 1;
          loop
            if workbook.sheets( s ).widths.exists( workbook.sheets( s ).comments( c ).column + t_c )
            then
              t_cw := 256 * workbook.sheets( s ).widths( workbook.sheets( s ).comments( c ).column + t_c ); 
              t_cw := trunc( ( t_cw + 18 ) / 256 * 7); -- assume default 11 point Calibri
            else
              t_cw := 64;
            end if;
            exit when t_w < t_cw;
            t_c := t_c + 1;
            t_w := t_w - t_cw;
          end loop;
          t_h := workbook.sheets( s ).comments( c ).height;
          t_xxx := t_xxx || to_char( '<x:Anchor>' || workbook.sheets( s ).comments( c ).column || ',15,' ||
                     workbook.sheets( s ).comments( c ).row || ',30,' ||
                     ( workbook.sheets( s ).comments( c ).column + t_c - 1 ) || ',' || round( t_w ) || ',' ||
                     ( workbook.sheets( s ).comments( c ).row + 1 + trunc( t_h / 20 ) ) || ',' || mod( t_h, 20 ) || '</x:Anchor>' );
          t_xxx := t_xxx || to_char( '<x:AutoFill>False</x:AutoFill><x:Row>' ||
            ( workbook.sheets( s ).comments( c ).row - 1 ) || '</x:Row><x:Column>' ||
            ( workbook.sheets( s ).comments( c ).column - 1 ) || '</x:Column></x:ClientData></v:shape>' );
        end loop;
        t_xxx := t_xxx || '</xml>';
        add1xml( t_excel, 'xl/drawings/vmlDrawing' || s || '.vml', t_xxx );
      end if;
--
    end loop;
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>';
    for s in 1 .. workbook.sheets.count()
    loop
      t_xxx := t_xxx || '
<Relationship Id="rId' || ( 9 + s ) || '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet' || s || '.xml"/>';
    end loop;
    t_xxx := t_xxx || '</Relationships>';
    add1xml( t_excel, 'xl/_rels/workbook.xml.rels', t_xxx );
    t_xxx := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="' || workbook.str_cnt || '" uniqueCount="' || workbook.strings.count() || '">';
    t_tmp := null;
    for i in 0 .. workbook.str_ind.count() - 1
    loop
      t_str := '<si><t>' || dbms_xmlgen.convert( substr( workbook.str_ind( i ), 1, 32000 ) ) || '</t></si>';
      if length( t_tmp ) + length( t_str ) > 32000
      then
        t_xxx := t_xxx || t_tmp;
        t_tmp := null;
      end if;
      t_tmp := t_tmp || t_str;
    end loop;
    t_xxx := t_xxx || t_tmp || '</sst>';
    add1xml( t_excel, 'xl/sharedStrings.xml', t_xxx );
    finish_zip( t_excel );
    clear_workbook;
    return t_excel;
  end;
--
  procedure save
    ( p_directory varchar2
    , p_filename varchar2
    )
  is
  begin
    blob2file( finish, p_directory, p_filename );
  end;
--
  procedure query2sheet
    ( p_sql varchar2
    , p_column_headers boolean := true
    , p_directory varchar2 := null
    , p_filename varchar2 := null
    , p_sheet pls_integer := null
    )
  is
    t_sheet pls_integer;
    t_c integer;
    t_col_cnt integer;
    t_desc_tab dbms_sql.desc_tab2;
    d_tab dbms_sql.date_table;
    n_tab dbms_sql.number_table;
    v_tab dbms_sql.varchar2_table;
    t_bulk_size pls_integer := 200;
    t_r integer;
    t_cur_row pls_integer;
  begin
    if p_sheet is null
    then
      new_sheet;
    end if;
    t_c := dbms_sql.open_cursor;
    dbms_sql.parse( t_c, p_sql, dbms_sql.native );
    dbms_sql.describe_columns2( t_c, t_col_cnt, t_desc_tab );
    for c in 1 .. t_col_cnt
    loop
      if p_column_headers
      then
        cell( c, 1, t_desc_tab( c ).col_name, p_sheet => t_sheet );
      end if;
--      dbms_output.put_line( t_desc_tab( c ).col_name || ' ' || t_desc_tab( c ).col_type );
      case
        when t_desc_tab( c ).col_type in ( 2, 100, 101 )
        then
          dbms_sql.define_array( t_c, c, n_tab, t_bulk_size, 1 );
        when t_desc_tab( c ).col_type in ( 12, 178, 179, 180, 181 , 231 )
        then
          dbms_sql.define_array( t_c, c, d_tab, t_bulk_size, 1 );
        when t_desc_tab( c ).col_type in ( 1, 8, 9, 96, 112 )
        then
          dbms_sql.define_array( t_c, c, v_tab, t_bulk_size, 1 );
        else
          null;
      end case;
    end loop;
--
    t_cur_row := case when p_column_headers then 2 else 1 end;
    t_sheet := nvl( p_sheet, workbook.sheets.count() );
--
    t_r := dbms_sql.execute( t_c );
    loop
      t_r := dbms_sql.fetch_rows( t_c );
      if t_r > 0
      then
        for c in 1 .. t_col_cnt
        loop
          case
            when t_desc_tab( c ).col_type in ( 2, 100, 101 )
            then
              dbms_sql.column_value( t_c, c, n_tab );
              for i in 0 .. t_r - 1
              loop
                if n_tab( i + n_tab.first() ) is not null
                then
                  cell( c, t_cur_row + i, n_tab( i + n_tab.first() ), p_sheet => t_sheet );
                end if;
              end loop;
              n_tab.delete;
            when t_desc_tab( c ).col_type in ( 12, 178, 179, 180, 181 , 231 )
            then
              dbms_sql.column_value( t_c, c, d_tab );
              for i in 0 .. t_r - 1
              loop
                if d_tab( i + d_tab.first() ) is not null
                then
                  cell( c, t_cur_row + i, d_tab( i + d_tab.first() ), p_sheet => t_sheet );
                end if;
              end loop;
              d_tab.delete;
            when t_desc_tab( c ).col_type in ( 1, 8, 9, 96, 112 )
            then
              dbms_sql.column_value( t_c, c, v_tab );
              for i in 0 .. t_r - 1
              loop
                if v_tab( i + v_tab.first() ) is not null
                then
                  cell( c, t_cur_row + i, v_tab( i + v_tab.first() ), p_sheet => t_sheet );
                end if;
              end loop;
              v_tab.delete;
            else
              null;
          end case;
        end loop;
      end if;
      exit when t_r != t_bulk_size;
      t_cur_row := t_cur_row + t_r;
    end loop;
    dbms_sql.close_cursor( t_c );
    if ( p_directory is not null and  p_filename is not null )
    then
      save( p_directory, p_filename );
    end if;
  exception
    when others
    then
      if dbms_sql.is_open( t_c )
      then
        dbms_sql.close_cursor( t_c );
      end if;
    raise;
  end;
end xlsx_builder_pkg;
/

