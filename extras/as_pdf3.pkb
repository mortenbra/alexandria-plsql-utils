CREATE OR REPLACE package body as_pdf3
is
--
  type tp_pls_tab is table of pls_integer index by pls_integer;
  type tp_objects_tab is table of number(10) index by pls_integer;
  type tp_pages_tab is table of blob index by pls_integer;
  type tp_settings is record
    ( page_width number
    , page_height number
    , margin_left number
    , margin_right number
    , margin_top number
    , margin_bottom number
    );
  type tp_font is record
    ( standard boolean
    , family varchar2(100)
    , style varchar2(2)  -- N Normal
                         -- I Italic
                         -- B Bold
                         -- BI Bold Italic
    , subtype varchar2(15)
    , name varchar2(100)
    , fontname varchar2(100)
    , char_width_tab tp_pls_tab
    , encoding varchar2(100)    , charset varchar2(1000)
    , compress_font boolean := true
    , fontsize number
    , unit_norm number
    , bb_xmin pls_integer
    , bb_ymin pls_integer
    , bb_xmax pls_integer
    , bb_ymax pls_integer
    , flags pls_integer
    , first_char pls_integer
    , last_char pls_integer
    , italic_angle number
    , ascent pls_integer
    , descent pls_integer
    , capheight pls_integer
    , stemv pls_integer
    , diff varchar2(32767)
    , cid boolean := false
    , fontfile2 blob
    , ttf_offset pls_integer
    , used_chars tp_pls_tab
    , numGlyphs pls_integer
    , indexToLocFormat pls_integer
    , loca tp_pls_tab
    , code2glyph tp_pls_tab
    , hmetrics tp_pls_tab
    );
  type tp_font_tab is table of tp_font index by pls_integer;
  type tp_img is record
    ( adler32 varchar2(8)
    , width pls_integer
    , height pls_integer
    , color_res pls_integer
    , color_tab raw(768)
    , greyscale boolean
    , pixels blob
    , type varchar2(5)
    , nr_colors pls_integer
    , transparancy_index pls_integer
    );
  type tp_img_tab is table of tp_img index by pls_integer;
  type tp_info is record
    ( title varchar2(1024)
    , author varchar2(1024)
    , subject varchar2(1024)
    , keywords varchar2(32767)
    );
  type tp_page_prcs is table of clob index by pls_integer;
--
-- globals
  g_pdf_doc blob; -- the PDF-document being constructed
  g_objects tp_objects_tab;
  g_pages tp_pages_tab;
  g_settings tp_settings;
  g_fonts tp_font_tab;
  g_used_fonts tp_pls_tab;
  g_current_font pls_integer;
  g_images tp_img_tab;
  g_x number;  -- current x-location of the "cursor"
  g_y number;  -- current y-location of the "cursor"
  g_info tp_info;
  g_page_nr pls_integer;
  g_page_prcs tp_page_prcs;
--
-- constants
  c_nl constant varchar2(2) := chr(13) || chr(10);
--
  function num2raw( p_value number )
  return raw
  is
  begin
    return hextoraw( to_char( p_value, 'FM0XXXXXXX' ) );
  end;
--
  function raw2num( p_value raw )
  return number
  is
  begin
    return to_number( rawtohex( p_value ), 'XXXXXXXX' );
  end;
--
  function raw2num( p_value raw, p_pos pls_integer, p_len pls_integer )
  return pls_integer
  is
  begin
    return to_number( rawtohex( utl_raw.substr( p_value, p_pos, p_len ) ), 'XXXXXXXX' );
  end;
--
  function to_short( p_val raw, p_factor number := 1 )
  return number
  is
    t_rv number;
  begin
    t_rv := to_number( rawtohex( p_val ), 'XXXXXXXXXX' );
    if t_rv > 32767
    then
      t_rv := t_rv - 65536;
    end if;
    return t_rv * p_factor;
  end;
--
  function blob2num( p_blob blob, p_len integer, p_pos integer )
  return number
  is
  begin
    return to_number( rawtohex( dbms_lob.substr( p_blob, p_len, p_pos ) ), 'xxxxxxxx' );
  end;
--
  function file2blob( p_dir varchar2, p_file_name varchar2 )
  return blob
  is
    t_raw raw(32767);
    t_blob blob;
    fh utl_file.file_type;
  begin
    fh := utl_file.fopen( p_dir, p_file_name, 'rb' );
    dbms_lob.createtemporary( t_blob, true );
    loop
      begin
        utl_file.get_raw( fh, t_raw );
        dbms_lob.append( t_blob, t_raw );
      exception
        when no_data_found
        then
          exit;
      end;
    end loop;
    utl_file.fclose( fh );
    return t_blob;
  exception
    when others
    then
      if utl_file.is_open( fh )
      then
        utl_file.fclose( fh );
      end if;
      raise;
  end;
--
  procedure init_core_fonts
  is
    function uncompress_withs( p_compressed_tab varchar2 )
    return tp_pls_tab
    is
      t_rv tp_pls_tab;
      t_tmp raw(32767);
    begin
      if p_compressed_tab is not null
      then
        t_tmp := utl_compress.lz_uncompress
          ( utl_encode.base64_decode( utl_raw.cast_to_raw( p_compressed_tab ) ) );
        for i in 0 .. 255
        loop
          t_rv( i ) := to_number( utl_raw.substr( t_tmp, i * 4 + 1, 4 ), '0xxxxxxx' );
        end loop;
      end if;
      return t_rv;
    end;
--
    procedure init_core_font
      ( p_ind pls_integer
      , p_family varchar2
      , p_style varchar2
      , p_name varchar2
      , p_compressed_tab varchar2
      )
    is
    begin
      g_fonts( p_ind ).family := p_family;
      g_fonts( p_ind ).style := p_style;
      g_fonts( p_ind ).name := p_name;
      g_fonts( p_ind ).fontname := p_name;
      g_fonts( p_ind ).standard := true;
      g_fonts( p_ind ).encoding := 'WE8MSWIN1252';
      g_fonts( p_ind ).charset := sys_context( 'userenv', 'LANGUAGE' );
      g_fonts( p_ind ).charset := substr( g_fonts( p_ind ).charset
                                        , 1
                                        , instr( g_fonts( p_ind ).charset, '.' )
                                        ) || g_fonts( p_ind ).encoding;
      g_fonts( p_ind ).char_width_tab := uncompress_withs( p_compressed_tab );
    end;
  begin
    init_core_font( 1, 'helvetica', 'N', 'Helvetica'
      ,  'H4sIAAAAAAAAC81Tuw3CMBC94FQMgMQOLAGVGzNCGtc0dAxAT+8lsgE7RKJFomOA'
      || 'SLT4frHjBEFJ8XSX87372C8A1Qr+Ax5gsWGYU7QBAK4x7gTnGLOS6xJPOd8w5NsM'
      || '2OvFvQidAP04j1nyN3F7iSNny3E6DylPeeqbNqvti31vMpfLZuzH86oPdwaeo6X+'
      || '5X6Oz5VHtTqJKfYRNVu6y0ZyG66rdcxzXJe+Q/KJ59kql+bTt5K6lKucXvxWeHKf'
      || '+p6Tfersfh7RHuXMZjHsdUkxBeWtM60gDjLTLoHeKsyDdu6m8VK3qhnUQAmca9BG'
      || 'Dq3nP+sV/4FcD6WOf9K/ne+hdav+DTuNLeYABAAA' );
--
    init_core_font( 2, 'helvetica', 'I', 'Helvetica-Oblique'
      ,  'H4sIAAAAAAAAC81Tuw3CMBC94FQMgMQOLAGVGzNCGtc0dAxAT+8lsgE7RKJFomOA'
      || 'SLT4frHjBEFJ8XSX87372C8A1Qr+Ax5gsWGYU7QBAK4x7gTnGLOS6xJPOd8w5NsM'
      || '2OvFvQidAP04j1nyN3F7iSNny3E6DylPeeqbNqvti31vMpfLZuzH86oPdwaeo6X+'
      || '5X6Oz5VHtTqJKfYRNVu6y0ZyG66rdcxzXJe+Q/KJ59kql+bTt5K6lKucXvxWeHKf'
      || '+p6Tfersfh7RHuXMZjHsdUkxBeWtM60gDjLTLoHeKsyDdu6m8VK3qhnUQAmca9BG'
      || 'Dq3nP+sV/4FcD6WOf9K/ne+hdav+DTuNLeYABAAA' );
--
    init_core_font( 3, 'helvetica', 'B', 'Helvetica-Bold'
      ,  'H4sIAAAAAAAAC8VSsRHCMAx0SJcBcgyRJaBKkxXSqKahYwB6+iyRTbhLSUdHRZUB'
      || 'sOWXLF8SKCn+ZL/0kizZuaJ2/0fn8XBu10SUF28n59wbvoCr51oTD61ofkHyhBwK'
      || '8rXusVaGAb4q3rXOBP4Qz+wfUpzo5FyO4MBr39IH+uLclFvmCTrz1mB5PpSD52N1'
      || 'DfqS988xptibWfbw9Sa/jytf+dz4PqQz6wi63uxxBpCXY7uUj88jNDNy1mYGdl97'
      || '856nt2f4WsOFed4SpzumNCvlT+jpmKC7WgH3PJn9DaZfA42vlgh96d+wkHy0/V95'
      || 'xyv8oj59QbvBN2I/iAuqEAAEAAA=' );
--
    init_core_font( 4, 'helvetica', 'BI', 'Helvetica-BoldOblique'
      ,  'H4sIAAAAAAAAC8VSsRHCMAx0SJcBcgyRJaBKkxXSqKahYwB6+iyRTbhLSUdHRZUB'
      || 'sOWXLF8SKCn+ZL/0kizZuaJ2/0fn8XBu10SUF28n59wbvoCr51oTD61ofkHyhBwK'
      || '8rXusVaGAb4q3rXOBP4Qz+wfUpzo5FyO4MBr39IH+uLclFvmCTrz1mB5PpSD52N1'
      || 'DfqS988xptibWfbw9Sa/jytf+dz4PqQz6wi63uxxBpCXY7uUj88jNDNy1mYGdl97'
      || '856nt2f4WsOFed4SpzumNCvlT+jpmKC7WgH3PJn9DaZfA42vlgh96d+wkHy0/V95'
      || 'xyv8oj59QbvBN2I/iAuqEAAEAAA=' );
--
    init_core_font( 5, 'times', 'N', 'Times-Roman'
      ,  'H4sIAAAAAAAAC8WSKxLCQAyG+3Bopo4bVHbwHGCvUNNT9AB4JEwvgUBimUF3wCNR'
      || 'qAoGRZL9twlQikR8kzTvZBtF0SP6O7Ej1kTnSRfEhHw7+Jy3J4XGi8w05yeZh2sE'
      || '4j312ZDeEg1gvSJy6C36L9WX1urr4xrolfrSrYmrUCeDPGMu5+cQ3Ur3OXvQ+TYf'
      || '+2FGexOZvTM1L3S3o5fJjGQJX2n68U2ur3X5m3cTvfbxsk9pcsMee60rdTjnhNkc'
      || 'Zip9HOv9+7/tI3Oif3InOdV/oLdx3gq2HIRaB1Ob7XPk35QwwxDyxg3e09Dv6nSf'
      || 'rxQjvty8ywDce9CXvdF9R+4y4o+7J1P/I9sABAAA' );
--
    init_core_font( 6, 'times', 'I', 'Times-Italic'
      ,  'H4sIAAAAAAAAC8WSPQ6CQBCFF+i01NB5g63tPcBegYZTeAB6SxNLjLUH4BTEeAYr'
      || 'Kwpj5ezsW2YgoKXFl2Hnb9+wY4x5m7+TOOJMdIFsRywodkfMBX9aSz7bXGp+gj6+'
      || 'R4TvOtJ3CU5Eq85tgGsbxG3QN8iFZY1WzpxXwkckFTR7e1G6osZGWT1bDuBnTeP5'
      || 'KtW/E71c0yB2IFbBphuyBXIL9Y/9fPvhf8se6vsa8nmeQtU6NSf6ch9fc8P9DpqK'
      || 'cPa5/I7VxDwruTN9kV3LDvQ+h1m8z4I4x9LIbnn/Fv6nwOdyGq+d33jk7/cxztyq'
      || 'XRhTz/it7Mscg7fT5CO+9ahnYk20Hww5IrwABAAA' );
--
    init_core_font( 7, 'times', 'B', 'Times-Bold'
      , 'H4sIAAAAAAAAC8VSuw3CQAy9XBqUAVKxAZkgHQUNEiukySxpqOjTMQEDZIrUDICE'
      || 'RHUVVfy9c0IQJcWTfbafv+ece7u/Izs553cgAyN/APagl+wjgN3XKZ5kmTg/IXkw'
      || 'h4JqXUEfAb1I1VvwFYysk9iCffmN4+gtccSr5nlwDpuTepCZ/MH0FZibDUnO7MoR'
      || 'HXdDuvgjpzNxgevG+dF/hr3dWfoNyEZ8Taqn+7d7ozmqpGM8zdMYruFrXopVjvY2'
      || 'in9gXe+5vBf1KfX9E6TOVBsb8i5iqwQyv9+a3Gg/Cv+VoDtaQ7xdPwfNYRDji09g'
      || 'X/FvLNGmO62B9jSsoFwgfM+jf1z/SPwrkTMBOkCTBQAEAAA=' );
--
    init_core_font( 8, 'times', 'BI', 'Times-BoldItalic'
      ,  'H4sIAAAAAAAAC8WSuw2DMBCGHegYwEuECajIAGwQ0TBFBnCfPktkAKagzgCRIqWi'
      || 'oso9fr+Qo5RB+nT2ve+wMWYzf+fgjKmOJFelPhENnS0xANJXHfwHSBtjfoI8nMMj'
      || 'tXo63xKW/Cx9ONRn3US6C/wWvYeYNr+LH2IY6cHGPkJfvsc5kX7mFjF+Vqs9iT6d'
      || 'zwEL26y1Qz62nWlvD5VSf4R9zPuon/ne+C45+XxXf5lnTGLTOZCXPx8v9Qfdjdid'
      || '5vD/f/+/pE/Ur14kG+xjTHRc84pZWsC2Hjk2+Hgbx78j4Z8W4DlL+rBnEN5Bie6L'
      || 'fsL+1u/InuYCdsdaeAs+RxftKfGdfQDlDF/kAAQAAA==' );
--
    init_core_font( 9, 'courier', 'N', 'Courier', null );
    for i in 0 .. 255
    loop
      g_fonts( 9 ).char_width_tab( i ) := 600;
    end loop;
--
    init_core_font( 10, 'courier', 'I', 'Courier-Oblique', null );
    g_fonts( 10 ).char_width_tab := g_fonts( 9 ).char_width_tab;
--
    init_core_font( 11, 'courier', 'B', 'Courier-Bold', null );
    g_fonts( 11 ).char_width_tab := g_fonts( 9 ).char_width_tab;
--
    init_core_font( 12, 'courier', 'BI', 'Courier-BoldOblique', null );
    g_fonts( 12 ).char_width_tab := g_fonts( 9 ).char_width_tab;
--
    init_core_font( 13, 'symbol', 'N', 'Symbol'
      ,  'H4sIAAAAAAAAC82SIU8DQRCFZ28xIE+cqcbha4tENKk/gQCJJ6AweIK9H1CHqKnp'
      || 'D2gTFBaDIcFwCQkJSTG83fem7SU0qYNLvry5nZ25t7NnZkv7c8LQrFhAP6GHZvEY'
      || 'HOB9ylxGubTfNVRc34mKpFonzBQ/gUZ6Ds7AN6i5lv1dKv8Ab1eKQYSV4hUcgZFq'
      || 'J/Sec7fQHtdTn3iqfvdrb7m3e2pZW+xDG3oIJ/Li3gfMr949rlU74DyT1/AuTX1f'
      || 'YGhOzTP8B0/RggsEX/I03vgXPrrslZjfM8/pGu40t2ZjHgud97F7337mXP/GO4h9'
      || '3WmPPaOJ/jrOs9yC52MlrtUzfWupfTX51X/L+13Vl/J/s4W2S3pSfSh5DmeXerMf'
      || '+LXhWQAEAAA=' );
--
    init_core_font( 14, 'zapfdingbats', 'N', 'ZapfDingbats'
      ,  'H4sIAAAAAAAAC83ROy9EQRjG8TkzjdJl163SSHR0EpdsVkSi2UahFhUljUKUIgoq'
      || 'CrvJCtFQyG6EbSSERGxhC0ofQAQFxbIi8T/7PoUPIOEkvzxzzsycdy7O/fUTtToX'
      || 'bnCuvHPOV8gk4r423ovkGQ5od5OTWMeesmBz/RuZIWv4wCAY4z/xjipeqflC9qAD'
      || 'aRwxrxkJievSFzrRh36tZ1zttL6nkGX+A27xrLnttE/IBji9x7UvcIl9nPJ9AL36'
      || 'd1L9hyihoDW10L62cwhNyhntryZVExYl3kMj+zym+CrJv6M8VozPmfr5L8uwJORL'
      || 'tox7NFHG/Obj79FlwhqZ1X292xn6CbAXP/fjjv6rJYyBtUdl1vxEO6fcRB7bMmJ3'
      || 'GYZsTN0GdrDL/Ao5j1GZNr5kwqydX5z1syoiYEq5gCtlSrXi+mVbi3PfVAuhoQAE'
      || 'AAA=' );
--
  end;
--
  function to_char_round
    ( p_value number
    , p_precision pls_integer := 2
    )
  return varchar2
  is
  begin
    return to_char( round( p_value, p_precision ), 'TM9', 'NLS_NUMERIC_CHARACTERS=.,' );
  end;
--
  procedure raw2pdfdoc( p_raw blob )
  is
  begin
    dbms_lob.append( g_pdf_doc, p_raw );
  end;
--
  procedure txt2pdfdoc( p_txt varchar2 )
  is
  begin
    raw2pdfdoc( utl_raw.cast_to_raw( p_txt || c_nl ) );
  end;
--
  function add_object( p_txt varchar2 := null )
  return number
  is
    t_self number(10);
  begin
    t_self := g_objects.count( );
    g_objects( t_self ) := dbms_lob.getlength( g_pdf_doc );
--
    if p_txt is null
    then
      txt2pdfdoc( t_self || ' 0 obj' );
    else
      txt2pdfdoc( t_self || ' 0 obj' || c_nl || '<<' || p_txt || '>>' || c_nl || 'endobj' );
    end if;
--
    return t_self;
  end;
--
  procedure add_object( p_txt varchar2 := null )
  is
    t_dummy number(10) := add_object( p_txt );
  begin
    null;
  end;
--
  function adler32( p_src in blob )
  return varchar2
  is
    s1 pls_integer := 1;
    s2 pls_integer := 0;
    n  pls_integer;
    step_size number;
    tmp varchar2(32766);
    c65521 constant pls_integer := 65521;
  begin
    step_size := trunc( 16383 / dbms_lob.getchunksize( p_src ) ) * dbms_lob.getchunksize( p_src );
    for j in 0 .. trunc( ( dbms_lob.getlength( p_src ) - 1 ) / step_size )
    loop
      tmp := rawtohex( dbms_lob.substr( p_src, step_size, j * step_size + 1 ) );
      for i in 1 .. length( tmp ) / 2
      loop
        n := to_number( substr( tmp, i * 2 - 1, 2 ), 'xx' );
        s1 := s1 + n;
        if s1 >= c65521
        then
          s1 := s1 - c65521;
        end if;
        s2 := s2 + s1;
        if s2 >= c65521
        then
          s2 := s2 - c65521;
        end if;
      end loop;
    end loop;
    return to_char( s2, 'fm0XXX' ) || to_char( s1, 'fm0XXX' );
  end;
--
  function flate_encode( p_val blob )
  return blob
  is
    t_blob blob;
  begin
    t_blob := hextoraw( '789C' );
    dbms_lob.copy( t_blob
                 , utl_compress.lz_compress( p_val )
                 , dbms_lob.lobmaxsize
                 , 3
                 , 11
                 );
    dbms_lob.trim( t_blob, dbms_lob.getlength( t_blob ) - 8 );
    dbms_lob.append( t_blob, hextoraw( adler32( p_val ) ) );
    return t_blob;
  end;
--
  procedure put_stream
    ( p_stream blob
    , p_compress boolean := true
    , p_extra varchar2 := ''
    , p_tag boolean := true
    )
  is
    t_blob blob;
    t_compress boolean := false;
  begin
    if p_compress and nvl( dbms_lob.getlength( p_stream ), 0 ) > 0
    then
      t_compress := true;
      t_blob := flate_encode( p_stream );
    else
      t_blob := p_stream;
    end if;
    txt2pdfdoc( case when p_tag then '<<' end
                || case when t_compress then '/Filter /FlateDecode ' end
                || '/Length ' || nvl( length( t_blob ), 0 )
                || p_extra
                || '>>' );
    txt2pdfdoc( 'stream' );
    raw2pdfdoc( t_blob );
    txt2pdfdoc( 'endstream' );
    if dbms_lob.istemporary( t_blob ) = 1
    then
      dbms_lob.freetemporary( t_blob );
    end if;
  end;
--
  function add_stream
    ( p_stream blob
    , p_extra varchar2 := ''
    , p_compress boolean := true
    )
  return number
  is
    t_self number(10);
  begin
    t_self := add_object;
    put_stream( p_stream
              , p_compress
              , p_extra
              );
    txt2pdfdoc( 'endobj' );
    return t_self;
  end;
--
  function subset_font( p_index pls_integer )
  return blob
  is
    t_tmp blob;
    t_header blob;
    t_tables blob;
    t_len pls_integer;
    t_code pls_integer;
    t_glyph pls_integer;
    t_offset pls_integer;
    t_factor pls_integer;
    t_unicode pls_integer;
    t_used_glyphs tp_pls_tab;
    t_fmt varchar2(10);
    t_utf16_charset varchar2(1000);
    t_raw raw(32767);
    t_v varchar2(32767);
    t_table_records raw(32767);
  begin
    if g_fonts( p_index ).cid
    then
      t_used_glyphs := g_fonts( p_index ).used_chars;
      t_used_glyphs( 0 ) := 0;
    else
      t_utf16_charset := substr( g_fonts( p_index ).charset, 1, instr( g_fonts( p_index ).charset, '.' ) ) || 'AL16UTF16';
      t_used_glyphs( 0 ) := 0;
      t_code := g_fonts( p_index ).used_chars.first;
      while t_code is not null
      loop
        t_unicode := to_number( rawtohex( utl_raw.convert( hextoraw( to_char( t_code, 'fm0x' ) )
                                                                    , t_utf16_charset
                                                                    , g_fonts( p_index ).charset  -- ???? database characterset ?????
                                                                    )
                                        ), 'XXXXXXXX' );
        if g_fonts( p_index ).flags = 4 -- a symbolic font
        then
-- assume code 32, space maps to the first code from the font
          t_used_glyphs( g_fonts( p_index ).code2glyph( g_fonts( p_index ).code2glyph.first + t_unicode - 32 ) ) := 0;
        else
          t_used_glyphs( g_fonts( p_index ).code2glyph( t_unicode ) ) := 0;
        end if;
        t_code := g_fonts( p_index ).used_chars.next( t_code );
      end loop;
    end if;
--
    dbms_lob.createtemporary( t_tables, true );
    t_header := utl_raw.concat( hextoraw( '00010000' )
                              , dbms_lob.substr( g_fonts( p_index ).fontfile2, 8, g_fonts( p_index ).ttf_offset + 4 )
                              );
    t_offset := 12 + blob2num( g_fonts( p_index ).fontfile2, 2, g_fonts( p_index ).ttf_offset + 4 ) * 16;
    t_table_records := dbms_lob.substr( g_fonts( p_index ).fontfile2
                                      , blob2num( g_fonts( p_index ).fontfile2, 2, g_fonts( p_index ).ttf_offset + 4 ) * 16
                                      , g_fonts( p_index ).ttf_offset + 12
                                      );
    for i in 1 .. blob2num( g_fonts( p_index ).fontfile2, 2, g_fonts( p_index ).ttf_offset + 4 )
    loop
      case utl_raw.cast_to_varchar2( utl_raw.substr( t_table_records, i * 16 - 15, 4 ) )
        when 'post'
        then
          dbms_lob.append( t_header
                         , utl_raw.concat( utl_raw.substr( t_table_records, i * 16 - 15, 4 ) -- tag
                                         , hextoraw( '00000000' ) -- checksum
                                         , num2raw( t_offset + dbms_lob.getlength( t_tables ) ) -- offset
                                         , num2raw( 32 ) -- length
                                         )
                         );
          dbms_lob.append( t_tables
                         , utl_raw.concat( hextoraw( '00030000' )
                                         , dbms_lob.substr( g_fonts( p_index ).fontfile2
                                                          , 28
                                                          , raw2num( t_table_records, i * 16 - 7, 4 ) + 5
                                                          )
                                         )
                         );
        when 'loca'
        then
          if g_fonts( p_index ).indexToLocFormat = 0
          then
            t_fmt := 'fm0XXX';
          else
            t_fmt := 'fm0XXXXXXX';
          end if;
          t_raw := null;
          dbms_lob.createtemporary( t_tmp, true );
          t_len := 0;
          for g in 0 .. g_fonts( p_index ).numGlyphs - 1
          loop
            t_raw := utl_raw.concat( t_raw, hextoraw( to_char( t_len, t_fmt ) ) );
            if utl_raw.length( t_raw ) > 32770
            then
              dbms_lob.append( t_tmp, t_raw );
              t_raw := null;
            end if;
            if t_used_glyphs.exists( g )
            then
              t_len := t_len + g_fonts( p_index ).loca( g + 1 ) - g_fonts( p_index ).loca( g );
            end if;
          end loop;
          t_raw := utl_raw.concat( t_raw, hextoraw( to_char( t_len, t_fmt ) ) );
          dbms_lob.append( t_tmp, t_raw );
          dbms_lob.append( t_header
                         , utl_raw.concat( utl_raw.substr( t_table_records, i * 16 - 15, 4 ) -- tag
                                         , hextoraw( '00000000' ) -- checksum
                                         , num2raw( t_offset + dbms_lob.getlength( t_tables ) ) -- offset
                                         , num2raw( dbms_lob.getlength( t_tmp ) ) -- length
                                         )
                         );
          dbms_lob.append( t_tables, t_tmp );
          dbms_lob.freetemporary( t_tmp );
        when 'glyf'
        then
          if g_fonts( p_index ).indexToLocFormat = 0
          then
            t_factor := 2;
          else
            t_factor := 1;
          end if;
          t_raw := null;
          dbms_lob.createtemporary( t_tmp, true );
          for g in 0 .. g_fonts( p_index ).numGlyphs - 1
          loop
            if (   t_used_glyphs.exists( g )
               and g_fonts( p_index ).loca( g + 1 ) > g_fonts( p_index ).loca( g )
               )
            then
              t_raw := utl_raw.concat( t_raw
                                     , dbms_lob.substr( g_fonts( p_index ).fontfile2
                                                      , ( g_fonts( p_index ).loca( g + 1 ) - g_fonts( p_index ).loca( g ) ) * t_factor
                                                      , g_fonts( p_index ).loca( g ) * t_factor + raw2num( t_table_records, i * 16 - 7, 4 ) + 1
                                                      )
                                     );
              if utl_raw.length( t_raw ) > 32778
              then
                dbms_lob.append( t_tmp, t_raw );
                t_raw := null;
              end if;
            end if;
          end loop;
          if utl_raw.length( t_raw ) > 0
          then
            dbms_lob.append( t_tmp, t_raw );
          end if;
          dbms_lob.append( t_header
                         , utl_raw.concat( utl_raw.substr( t_table_records, i * 16 - 15, 4 ) -- tag
                                         , hextoraw( '00000000' ) -- checksum
                                         , num2raw( t_offset + dbms_lob.getlength( t_tables ) ) -- offset
                                         , num2raw( dbms_lob.getlength( t_tmp ) ) -- length
                                         )
                         );
          dbms_lob.append( t_tables, t_tmp );
          dbms_lob.freetemporary( t_tmp );
        else
          dbms_lob.append( t_header
                         , utl_raw.concat( utl_raw.substr( t_table_records, i * 16 - 15, 4 )    -- tag
                                         , utl_raw.substr( t_table_records, i * 16 - 11, 4 )    -- checksum
                                         , num2raw( t_offset + dbms_lob.getlength( t_tables ) ) -- offset
                                         , utl_raw.substr( t_table_records, i * 16 - 3, 4 )     -- length
                                         )
                         );
          dbms_lob.copy( t_tables
                       , g_fonts( p_index ).fontfile2
                       , raw2num( t_table_records, i * 16 - 3, 4 )
                       , dbms_lob.getlength( t_tables ) + 1
                       , raw2num( t_table_records, i * 16 - 7, 4 ) + 1
                       );
      end case;
    end loop;
    dbms_lob.append( t_header, t_tables );
    dbms_lob.freetemporary( t_tables );
    return t_header;
  end;
--
  function add_font( p_index pls_integer )
  return number
  is
    t_self number(10);
    t_fontfile number(10);
    t_font_subset blob;
    t_used pls_integer;
    t_used_glyphs tp_pls_tab;
    t_w varchar2(32767);
    t_unicode pls_integer;
    t_utf16_charset varchar2(1000);
    t_width number;
  begin
    if g_fonts( p_index ).standard
    then
      return add_object( '/Type/Font'
                       || '/Subtype/Type1'
                       || '/BaseFont/' || g_fonts( p_index ).name
                       || '/Encoding/WinAnsiEncoding' -- code page 1252
                       );
    end if;
--
    if g_fonts( p_index ).cid
    then
      t_self := add_object;
      txt2pdfdoc( '<</Type/Font/Subtype/Type0/Encoding/Identity-H'
                || '/BaseFont/' || g_fonts( p_index ).name
                || '/DescendantFonts ' || to_char( t_self + 1 ) || ' 0 R'
                || '/ToUnicode ' || to_char( t_self + 8 ) || ' 0 R'
                || '>>' );
      txt2pdfdoc( 'endobj' );
      add_object;
      txt2pdfdoc( '[' || to_char( t_self + 2 ) || ' 0 R]' );
      txt2pdfdoc( 'endobj' );
      add_object( '/Type/Font/Subtype/CIDFontType2/CIDToGIDMap/Identity/DW 1000'
                || '/BaseFont/' || g_fonts( p_index ).name
                || '/CIDSystemInfo ' || to_char( t_self + 3 ) || ' 0 R'
                || '/W ' || to_char( t_self + 4 ) || ' 0 R'
                || '/FontDescriptor ' || to_char( t_self + 5 ) || ' 0 R' );
      add_object( '/Ordering(Identity) /Registry(Adobe) /Supplement 0' );
--
      t_utf16_charset := substr( g_fonts( p_index ).charset, 1, instr( g_fonts( p_index ).charset, '.' ) ) || 'AL16UTF16';
      t_used_glyphs := g_fonts( p_index ).used_chars;
      t_used_glyphs( 0 ) := 0;
      t_used := t_used_glyphs.first();
      while t_used is not null
      loop
        if g_fonts( p_index ).hmetrics.exists( t_used )
        then
          t_width := g_fonts( p_index ).hmetrics( t_used );
        else
          t_width := g_fonts( p_index ).hmetrics( g_fonts( p_index ).hmetrics.last() );
        end if;
        t_width := trunc( t_width * g_fonts( p_index ).unit_norm );
        if t_used_glyphs.prior( t_used ) = t_used - 1
        then
          t_w := t_w || ' ' || t_width;
        else
          t_w := t_w || '] ' || t_used || ' [' || t_width;
        end if;
        t_used := t_used_glyphs.next( t_used );
      end loop;
      t_w := '[' || ltrim( t_w, '] ' ) || ']]';
      add_object;
      txt2pdfdoc( t_w );
      txt2pdfdoc( 'endobj' );
      add_object
        (    '/Type/FontDescriptor'
          || '/FontName/' || g_fonts( p_index ).name
          || '/Flags ' || g_fonts( p_index ).flags
          || '/FontBBox [' || g_fonts( p_index ).bb_xmin
          || ' ' || g_fonts( p_index ).bb_ymin
          || ' ' || g_fonts( p_index ).bb_xmax
          || ' ' || g_fonts( p_index ).bb_ymax
          || ']'
          || '/ItalicAngle ' || to_char_round( g_fonts( p_index ).italic_angle )
          || '/Ascent ' || g_fonts( p_index ).ascent
          || '/Descent ' || g_fonts( p_index ).descent
          || '/CapHeight ' || g_fonts( p_index ).capheight
          || '/StemV ' || g_fonts( p_index ).stemv
          || '/FontFile2 ' || to_char( t_self + 6 ) || ' 0 R' );
      t_fontfile := add_stream( g_fonts( p_index ).fontfile2
                              , '/Length1 ' || dbms_lob.getlength( g_fonts( p_index ).fontfile2 )
                              , g_fonts( p_index ).compress_font
                              );
      t_font_subset := subset_font( p_index );
      t_fontfile := add_stream( t_font_subset
                              , '/Length1 ' || dbms_lob.getlength( t_font_subset )
                              , g_fonts( p_index ).compress_font
                              );
      declare
        t_g2c tp_pls_tab;
        t_code     pls_integer;
        t_c_start  pls_integer;
        t_map varchar2(32767);
        t_cmap varchar2(32767);
        t_cor pls_integer;
        t_cnt pls_integer;
      begin
        t_code := g_fonts( p_index ).code2glyph.first;
        if g_fonts( p_index ).flags = 4 -- a symbolic font
        then
-- assume code 32, space maps to the first code from the font
          t_cor := t_code - 32;
        else
          t_cor := 0;
        end if;
        while t_code is not null
        loop
          t_g2c( g_fonts( p_index ).code2glyph( t_code ) ) := t_code - t_cor;
          t_code := g_fonts( p_index ).code2glyph.next( t_code );
        end loop;
        t_cnt := 0;
        t_used_glyphs := g_fonts( p_index ).used_chars;
        t_used := t_used_glyphs.first();
        while t_used is not null
        loop
          t_map := t_map || '<' || to_char( t_used, 'FM0XXX' )
                 || '> <' || to_char( t_g2c( t_used ), 'FM0XXX' )
                 || '>' || chr( 10 );
          if t_cnt = 99
          then
            t_cnt := 0;
            t_cmap := t_cmap || chr( 10 ) || '100 beginbfchar' || chr( 10 ) || t_map || 'endbfchar';
            t_map := '';
          else
            t_cnt := t_cnt + 1;
          end if;
          t_used := t_used_glyphs.next( t_used );
        end loop;
        if t_cnt > 0
        then
          t_cmap := t_cnt || ' beginbfchar' || chr( 10 ) || t_map || 'endbfchar';
        end if;
        t_fontfile := add_stream( utl_raw.cast_to_raw(
'/CIDInit /ProcSet findresource begin 12 dict begin
begincmap
/CIDSystemInfo
<< /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def
/CMapName /Adobe-Identity-UCS def /CMapType 2 def
1 begincodespacerange
<0000> <FFFF>
endcodespacerange
' || t_cmap || '
endcmap
CMapName currentdict /CMap defineresource pop
end
end' ) );
      end;
      return t_self;
    end if;
--
    g_fonts( p_index ).first_char := g_fonts( p_index ).used_chars.first();
    g_fonts( p_index ).last_char := g_fonts( p_index ).used_chars.last();
    t_self := add_object;
    txt2pdfdoc( '<</Type /Font '
              || '/Subtype /' || g_fonts( p_index ).subtype
              || ' /BaseFont /' || g_fonts( p_index ).name
              || ' /FirstChar ' || g_fonts( p_index ).first_char
              || ' /LastChar ' || g_fonts( p_index ).last_char
              || ' /Widths ' || to_char( t_self + 1 ) || ' 0 R'
              || ' /FontDescriptor ' || to_char( t_self + 2 ) || ' 0 R'
              || ' /Encoding ' || to_char( t_self + 3 ) || ' 0 R'
              || ' >>' );
    txt2pdfdoc( 'endobj' );
    add_object;
    txt2pdfdoc( '[' );
      begin
        for i in g_fonts( p_index ).first_char .. g_fonts( p_index ).last_char
        loop
          txt2pdfdoc( g_fonts( p_index ).char_width_tab( i ) );
        end loop;
      exception
        when others
        then
          dbms_output.put_line( '**** ' || g_fonts( p_index ).name );
      end;
      txt2pdfdoc( ']' );
      txt2pdfdoc( 'endobj' );
      add_object
        (    '/Type /FontDescriptor'
          || ' /FontName /' || g_fonts( p_index ).name
          || ' /Flags ' || g_fonts( p_index ).flags
          || ' /FontBBox [' || g_fonts( p_index ).bb_xmin
          || ' ' || g_fonts( p_index ).bb_ymin
          || ' ' || g_fonts( p_index ).bb_xmax
          || ' ' || g_fonts( p_index ).bb_ymax
          || ']'
          || ' /ItalicAngle ' || to_char_round( g_fonts( p_index ).italic_angle )
          || ' /Ascent ' || g_fonts( p_index ).ascent
          || ' /Descent ' || g_fonts( p_index ).descent
          || ' /CapHeight ' || g_fonts( p_index ).capheight
          || ' /StemV ' || g_fonts( p_index ).stemv
          || case
               when g_fonts( p_index ).fontfile2 is not null
                 then ' /FontFile2 ' || to_char( t_self + 4 ) || ' 0 R'
             end );
      add_object(    '/Type /Encoding /BaseEncoding /WinAnsiEncoding '
                         || g_fonts( p_index ).diff
                         || ' ' );
      if g_fonts( p_index ).fontfile2 is not null
      then
        t_font_subset := subset_font( p_index );
        t_fontfile :=
          add_stream( t_font_subset
                    , '/Length1 ' || dbms_lob.getlength( t_font_subset )
                    , g_fonts( p_index ).compress_font
                    );
    end if;
    return t_self;
  end;
--
  procedure add_image( p_img tp_img )
  is
    t_pallet number(10);
  begin
    if p_img.color_tab is not null
    then
      t_pallet := add_stream( p_img.color_tab );
    else
      t_pallet := add_object;  -- add an empty object
      txt2pdfdoc( 'endobj' );
    end if;
    add_object;
    txt2pdfdoc( '<</Type /XObject /Subtype /Image'
              ||  ' /Width ' || to_char( p_img.width )
              || ' /Height ' || to_char( p_img.height )
              || ' /BitsPerComponent ' || to_char( p_img.color_res )
              );
--
    if p_img.transparancy_index is not null
    then
      txt2pdfdoc( '/Mask [' || p_img.transparancy_index || ' ' || p_img.transparancy_index || ']' );
    end if;
    if p_img.color_tab is null
    then
      if p_img.greyscale
      then
        txt2pdfdoc( '/ColorSpace /DeviceGray' );
      else
        txt2pdfdoc( '/ColorSpace /DeviceRGB' );
      end if;
    else
      txt2pdfdoc(    '/ColorSpace [/Indexed /DeviceRGB '
                || to_char( utl_raw.length( p_img.color_tab ) / 3 - 1 )
                || ' ' || to_char( t_pallet ) || ' 0 R]'
                );
    end if;
--
    if p_img.type = 'jpg'
    then
      put_stream( p_img.pixels, false, '/Filter /DCTDecode', false );
    elsif p_img.type = 'png'
    then
      put_stream( p_img.pixels, false
                ,  ' /Filter /FlateDecode /DecodeParms <</Predictor 15 '
                || '/Colors ' || p_img.nr_colors
                || '/BitsPerComponent ' || p_img.color_res
                || ' /Columns ' || p_img.width
                || ' >> '
                , false );
    else
      put_stream( p_img.pixels, p_tag => false );
    end if;
    txt2pdfdoc( 'endobj' );
  end;
--
  function add_resources
  return number
  is
    t_ind pls_integer;
    t_self number(10);
    t_fonts tp_objects_tab;
  begin
--
    t_ind := g_used_fonts.first;
    while t_ind is not null
    loop
      t_fonts( t_ind ) := add_font( t_ind );
      t_ind := g_used_fonts.next( t_ind );
    end loop;
--
    t_self := add_object;
    txt2pdfdoc( '<</ProcSet [/PDF /Text]' );
--
    if g_used_fonts.count() > 0
    then
      txt2pdfdoc( '/Font <<' );
      t_ind := g_used_fonts.first;
      while t_ind is not null
      loop
        txt2pdfdoc( '/F'|| to_char( t_ind ) || ' '
                  || to_char( t_fonts( t_ind ) ) || ' 0 R'
                  );
        t_ind := g_used_fonts.next( t_ind );
      end loop;
      txt2pdfdoc( '>>' );
    end if;
--
    if g_images.count( ) > 0
    then
      txt2pdfdoc( '/XObject <<' );
      for i in g_images.first .. g_images.last
      loop
        txt2pdfdoc( '/I' || to_char( i ) || ' ' || to_char( t_self + 2 * i ) || ' 0 R' );
      end loop;
      txt2pdfdoc( '>>' );
    end if;
--
    txt2pdfdoc( '>>' );
    txt2pdfdoc( 'endobj' );
--
    if g_images.count( ) > 0
    then
      for i in g_images.first .. g_images.last
      loop
        add_image( g_images( i ) );
      end loop;
    end if;
    return t_self;
  end;
--
  procedure add_page
    ( p_page_ind pls_integer
    , p_parent number
    , p_resources number
    )
  is
    t_content number(10);
  begin
    t_content := add_stream( g_pages( p_page_ind ) );
    add_object;
    txt2pdfdoc( '<< /Type /Page' );
    txt2pdfdoc( '/Parent ' || to_char( p_parent ) || ' 0 R' );
    txt2pdfdoc( '/Contents ' || to_char( t_content ) || ' 0 R' );
    txt2pdfdoc( '/Resources ' || to_char( p_resources ) || ' 0 R' );
    txt2pdfdoc( '>>' );
    txt2pdfdoc( 'endobj' );
  end;
--
  function add_pages
  return number
  is
    t_self number(10);
    t_resources number(10);
  begin
    t_resources := add_resources;
    t_self := add_object;
    txt2pdfdoc( '<</Type/Pages/Kids [' );
--
    for i in g_pages.first .. g_pages.last
    loop
      txt2pdfdoc( to_char( t_self + i * 2 + 2 ) || ' 0 R' );
    end loop;
--
    txt2pdfdoc( ']' );
    txt2pdfdoc( '/Count ' || g_pages.count() );
    txt2pdfdoc(    '/MediaBox [0 0 '
                || to_char_round( g_settings.page_width
                                , 0
                                )
                || ' '
                || to_char_round( g_settings.page_height
                                , 0
                                )
                || ']' );
    txt2pdfdoc( '>>' );
    txt2pdfdoc( 'endobj' );
--
    if g_pages.count() > 0
    then
      for i in g_pages.first .. g_pages.last
      loop
        add_page( i, t_self, t_resources );
      end loop;
    end if;
--
    return t_self;
  end;
--
  function add_catalogue
  return number
  is
  begin
    return add_object( '/Type/Catalog'
                     || '/Pages ' || to_char( add_pages ) || ' 0 R'
                     || '/OpenAction [0 /XYZ null null 0.77]'
                     );
  end;
--
  function add_info
  return number
  is
    t_banner varchar2( 1000 );
  begin
    begin
      select    'running on '
             || replace( replace( replace( substr( banner
                                                 , 1
                                                 , 950
                                                 )
                                         , '\'
                                         , '\\'
                                         )
                                , '('
                                , '\('
                                )
                       , ')'
                       , '\)'
                       )
      into t_banner
      from v$version
      where instr( upper( banner )
                 , 'DATABASE'
                 ) > 0;
      t_banner := '/Producer (' || t_banner || ')';
    exception
      when others
      then
        null;
    end;
--
    return add_object( to_char( sysdate, '"/CreationDate (D:"YYYYMMDDhh24miss")"' )
                     || '/Creator (AS-PDF 0.3.0 by Anton Scheffer)'
                     || t_banner
                     || '/Title <FEFF' || utl_i18n.string_to_raw( g_info.title, 'AL16UTF16' ) || '>'
                     || '/Author <FEFF' || utl_i18n.string_to_raw( g_info.author, 'AL16UTF16' ) || '>'
                     || '/Subject <FEFF' || utl_i18n.string_to_raw( g_info.subject, 'AL16UTF16' ) || '>'
                     || '/Keywords <FEFF' || utl_i18n.string_to_raw( g_info.keywords, 'AL16UTF16' ) || '>'
                     );
  end;
--
  procedure finish_pdf
  is
    t_xref number;
    t_info number(10);
    t_catalogue number(10);
  begin
    if g_pages.count = 0
    then
      new_page;
    end if;
    if g_page_prcs.count > 0
    then
      for i in g_pages.first .. g_pages.last
      loop
        g_page_nr := i;
        for p in g_page_prcs.first .. g_page_prcs.last
        loop  
          begin
            execute immediate replace( replace( g_page_prcs( p ), '#PAGE_NR#', i + 1 ), '"PAGE_COUNT#', g_pages.count );
          exception
            when others then null;
          end;
        end loop;
      end loop;
    end if;
    dbms_lob.createtemporary( g_pdf_doc, true );
    txt2pdfdoc( '%PDF-1.3' );
    raw2pdfdoc( hextoraw( '25E2E3CFD30D0A' ) );          -- add a hex comment
    t_info := add_info;
    t_catalogue := add_catalogue;
    t_xref := dbms_lob.getlength( g_pdf_doc );
    txt2pdfdoc( 'xref' );
    txt2pdfdoc( '0 ' || to_char( g_objects.count() ) );
    txt2pdfdoc( '0000000000 65535 f ' );
    for i in 1 .. g_objects.count( ) - 1
    loop
      txt2pdfdoc( to_char( g_objects( i ), 'fm0000000000' ) || ' 00000 n' );
                        -- this line should be exactly 20 bytes, including EOL
    end loop;
    txt2pdfdoc( 'trailer' );
    txt2pdfdoc( '<< /Root ' || to_char( t_catalogue ) || ' 0 R' );
    txt2pdfdoc( '/Info ' || to_char( t_info ) || ' 0 R' );
    txt2pdfdoc( '/Size ' || to_char( g_objects.count() ) );
    txt2pdfdoc( '>>' );
    txt2pdfdoc( 'startxref' );
    txt2pdfdoc( to_char( t_xref ) );
    txt2pdfdoc( '%%EOF' );
--
    g_objects.delete;
    for i in g_pages.first .. g_pages.last
    loop
      dbms_lob.freetemporary( g_pages( i ) );
    end loop;
    g_objects.delete;
    g_pages.delete;
    g_fonts.delete;
    g_used_fonts.delete;
    g_page_prcs.delete;
    if g_images.count() > 0
    then
      for i in g_images.first .. g_images.last
      loop
        if dbms_lob.istemporary( g_images( i ).pixels ) = 1
        then
          dbms_lob.freetemporary( g_images( i ).pixels );
        end if;
      end loop;
      g_images.delete;
    end if;
  end;
--
  function conv2uu( p_value number, p_unit varchar2 )
  return number
  is
   c_inch constant number := 25.40025;
  begin
    return round( case lower( p_unit )
                    when 'mm' then p_value * 72 / c_inch
                    when 'cm' then p_value * 720 / c_inch
                    when 'pt' then p_value          -- also point
                    when 'point' then p_value
                    when 'inch'  then p_value * 72
                    when 'in'    then p_value * 72  -- also inch
                    when 'pica'  then p_value * 12
                    when 'p'     then p_value * 12  -- also pica
                    when 'pc'    then p_value * 12  -- also pica
                    when 'em'    then p_value * 12  -- also pica
                    when 'px'    then p_value       -- pixel voorlopig op point zetten
                    when 'px'    then p_value * 0.8 -- pixel
                    else null
                  end
                , 3
                );
  end;
--
  procedure set_page_size
    ( p_width number
    , p_height number
    , p_unit varchar2 := 'cm'
    )
  is
  begin
    g_settings.page_width := conv2uu( p_width, p_unit );
    g_settings.page_height := conv2uu( p_height, p_unit );
  end;
--
  procedure set_page_format( p_format varchar2 := 'A4' )
  is
  begin
    case upper( p_format )
      when 'A3'
      then
        set_page_size( 420, 297, 'mm' );
      when 'A4'
      then
        set_page_size( 297, 210, 'mm' );
      when 'A5'
      then
        set_page_size( 210, 148, 'mm' );
      when 'A6'
      then
        set_page_size( 148, 105, 'mm' );
      when 'LEGAL'
      then
        set_page_size( 14, 8.5, 'in' );
      when 'LETTER'
      then
        set_page_size( 11, 8.5, 'in' );
      when 'QUARTO'
      then
        set_page_size( 11, 9, 'in' );
      when 'EXECUTIVE'
      then
        set_page_size( 10.5, 7.25, 'in' );
      else
        null;
    end case;
  end;
--
  procedure set_page_orientation( p_orientation varchar2 := 'PORTRAIT' )
  is
    t_tmp number;
  begin
    if (  (   upper( p_orientation ) in ( 'L', 'LANDSCAPE' )
          and g_settings.page_height > g_settings.page_width
          )
       or ( upper( p_orientation ) in( 'P', 'PORTRAIT' )
          and g_settings.page_height < g_settings.page_width
          )
       )
    then
      t_tmp := g_settings.page_width;
      g_settings.page_width := g_settings.page_height;
      g_settings.page_height := t_tmp;
    end if;
  end;
--
  procedure set_margins
    ( p_top number := null
    , p_left number := null
    , p_bottom number := null
    , p_right number := null
    , p_unit varchar2 := 'cm'
    )
  is
    t_tmp number;
  begin
    t_tmp := nvl( conv2uu( p_top, p_unit ), -1 );
    if t_tmp < 0 or t_tmp > g_settings.page_height
    then
      t_tmp := conv2uu( 3, 'cm' );
    end if;
    g_settings.margin_top := t_tmp;
    t_tmp := nvl( conv2uu( p_bottom, p_unit ), -1 );
    if t_tmp < 0 or t_tmp > g_settings.page_height
    then
      t_tmp := conv2uu( 4, 'cm' );
    end if;
    g_settings.margin_bottom := t_tmp;
    t_tmp := nvl( conv2uu( p_left, p_unit ), -1 );
    if t_tmp < 0 or t_tmp > g_settings.page_width
    then
      t_tmp := conv2uu( 1, 'cm' );
    end if;
    g_settings.margin_left := t_tmp;
    t_tmp := nvl( conv2uu( p_right, p_unit ), -1 );
    if t_tmp < 0 or t_tmp > g_settings.page_width
    then
      t_tmp := conv2uu( 1, 'cm' );
    end if;
    g_settings.margin_right := t_tmp;
--
    if g_settings.margin_top + g_settings.margin_bottom + conv2uu( 1, 'cm' )> g_settings.page_height
    then
      g_settings.margin_top := 0;
      g_settings.margin_bottom := 0;
    end if;
    if g_settings.margin_left + g_settings.margin_right + conv2uu( 1, 'cm' )> g_settings.page_width
    then
      g_settings.margin_left := 0;
      g_settings.margin_right := 0;
    end if;
  end;
--
  procedure set_info
    ( p_title varchar2 := null
    , p_author varchar2 := null
    , p_subject varchar2 := null
    , p_keywords varchar2 := null
    )
  is
  begin
    g_info.title := substr( p_title, 1, 1024 );
    g_info.author := substr( p_author, 1, 1024 );
    g_info.subject := substr( p_subject, 1, 1024 );
    g_info.keywords := substr( p_keywords, 1, 16383 );
  end;
--
  procedure init
  is
  begin
    g_objects.delete;
    g_pages.delete;
    g_fonts.delete;
    g_used_fonts.delete;
    g_page_prcs.delete;
    g_images.delete;
    g_settings := null;
    g_current_font := null;
    g_x := null;
    g_y := null;
    g_info := null;
    g_page_nr := null;
    g_objects( 0 ) := 0;
    init_core_fonts;
    set_page_format;
    set_page_orientation;
    set_margins;
  end;
--
  function get_pdf
  return blob
  is
  begin
    finish_pdf;
    return g_pdf_doc;
  end;
--
  procedure save_pdf
    ( p_dir varchar2 := 'MY_DIR'
    , p_filename varchar2 := 'my.pdf'
    , p_freeblob boolean := true
    )
  is
    t_fh utl_file.file_type;
    t_len pls_integer := 32767;
  begin
    finish_pdf;
    t_fh := utl_file.fopen( p_dir, p_filename, 'wb' );
    for i in 0 .. trunc( ( dbms_lob.getlength( g_pdf_doc ) - 1 ) / t_len )
    loop
      utl_file.put_raw( t_fh
                      , dbms_lob.substr( g_pdf_doc
                                       , t_len
                                       , i * t_len + 1
                                       )
                      );
    end loop;
    utl_file.fclose( t_fh );
    if p_freeblob
    then
      dbms_lob.freetemporary( g_pdf_doc );
    end if;
  end;
--
  procedure raw2page( p_txt blob )
  is
  begin
    if g_pages.count() = 0
    then
      new_page;
    end if;
    dbms_lob.append( g_pages( coalesce( g_page_nr, g_pages.count( ) - 1 ) )
                   , utl_raw.concat( p_txt, hextoraw( '0D0A' ) )
                   );
  end;
--
  procedure txt2page( p_txt varchar2 )
  is
  begin
    raw2page( utl_raw.cast_to_raw( p_txt ) );
  end;
--
  procedure output_font_to_doc( p_output_to_doc boolean )
  is
  begin
    if p_output_to_doc
    then
      txt2page( 'BT /F' || g_current_font || ' '
              || to_char_round( g_fonts( g_current_font ).fontsize ) || ' Tf ET'
              );
    end if;
  end;
--
  procedure set_font
    ( p_index pls_integer
    , p_fontsize_pt number
    , p_output_to_doc boolean := true
    )
  is
  begin
    if p_index is not null
    then
      g_used_fonts( p_index ) := 0;
      g_current_font := p_index;
      g_fonts( p_index ).fontsize := p_fontsize_pt;
      output_font_to_doc( p_output_to_doc );
    end if;
  end;
--
  function set_font
    ( p_fontname varchar2
    , p_fontsize_pt number
    , p_output_to_doc boolean := true
    )
  return pls_integer
  is
    t_fontname varchar2(100);
  begin
    if p_fontname is null
    then
      if (  g_current_font is not null
         and p_fontsize_pt != g_fonts( g_current_font ).fontsize
         )
      then
        g_fonts( g_current_font ).fontsize := p_fontsize_pt;
        output_font_to_doc( p_output_to_doc );
      end if;
      return g_current_font;
    end if;
--
    t_fontname := lower( p_fontname );
    for i in g_fonts.first .. g_fonts.last
    loop
      if lower( g_fonts( i ).fontname ) = t_fontname
      then
        exit when g_current_font = i and g_fonts( i ).fontsize = p_fontsize_pt and g_page_nr is null;
        g_fonts( i ).fontsize := coalesce( p_fontsize_pt
                                         , g_fonts( nvl( g_current_font, i ) ).fontsize
                                         , 12
                                         );
        g_current_font := i;
        g_used_fonts( i ) := 0;
        output_font_to_doc( p_output_to_doc );
        return g_current_font;
      end if;
    end loop;
    return null;
  end;
--
  procedure set_font
    ( p_fontname varchar2
    , p_fontsize_pt number
    , p_output_to_doc boolean := true
    )
  is
    t_dummy pls_integer;
  begin
    t_dummy := set_font( p_fontname, p_fontsize_pt, p_output_to_doc );
  end;
--
  function set_font
    ( p_family varchar2
    , p_style varchar2 := 'N'
    , p_fontsize_pt number := null
    , p_output_to_doc boolean := true
    )
  return pls_integer
  is
    t_family varchar2(100);
    t_style varchar2(100);
  begin
    if p_family is null and g_current_font is null
    then
      return null;
    end if;
    if p_family is null and  p_style is null and p_fontsize_pt is null
    then
      return null;
    end if;
    t_family := coalesce( lower( p_family )
                        , g_fonts( g_current_font ).family
                        );
    t_style := upper( p_style );
    t_style := case t_style
                 when 'NORMAL' then 'N'
                 when 'REGULAR' then 'N'
                 when 'BOLD' then 'B'
                 when 'ITALIC' then 'I'
                 when 'OBLIQUE' then 'I'
                 else t_style
               end;
    t_style := coalesce( t_style
                       , case when g_current_font is null then 'N' else g_fonts( g_current_font ).style end
                       );
--
    for i in g_fonts.first .. g_fonts.last
    loop
      if (   g_fonts( i ).family = t_family
         and g_fonts( i ).style = t_style
         )
      then
        return set_font( g_fonts( i ).fontname, p_fontsize_pt, p_output_to_doc );
      end if;
    end loop;
    return null;
  end;
--
  procedure set_font
    ( p_family varchar2
    , p_style varchar2 := 'N'
    , p_fontsize_pt number := null
    , p_output_to_doc boolean := true
    )
  is
    t_dummy pls_integer;
  begin
    t_dummy := set_font( p_family, p_style, p_fontsize_pt, p_output_to_doc );
  end;
--
  procedure new_page
  is
  begin
    g_pages( g_pages.count() ) := null;
    dbms_lob.createtemporary( g_pages( g_pages.count() - 1 ), true );
    if g_current_font is not null and g_pages.count() > 0
    then
      txt2page( 'BT /F' || g_current_font || ' '
              || to_char_round( g_fonts( g_current_font ).fontsize )
              || ' Tf ET'
              );
    end if;
    g_x := null;
    g_y := null;
  end;
--
  function pdf_string( p_txt in blob )
  return blob
  is
    t_rv blob;
    t_ind integer;
    type tp_tab_raw is table of raw(1);
    tab_raw tp_tab_raw
      := tp_tab_raw( utl_raw.cast_to_raw( '\' )
                   , utl_raw.cast_to_raw( '(' )
                   , utl_raw.cast_to_raw( ')' )
                   );
  begin
    t_rv := p_txt;
    for i in tab_raw.first .. tab_raw.last
    loop
      t_ind := -1;
      loop
        t_ind := dbms_lob.instr( t_rv
                               , tab_raw( i )
                               , t_ind + 2
                               );
        exit when t_ind <= 0;
        dbms_lob.copy( t_rv
                     , t_rv
                     , dbms_lob.lobmaxsize
                     , t_ind + 1
                     , t_ind
                     );
        dbms_lob.copy( t_rv
                     , utl_raw.cast_to_raw( '\' )
                     , 1
                     , t_ind
                     , 1
                     );
      end loop;
    end loop;
    return t_rv;
  end;
--
  function txt2raw( p_txt varchar2 )
  return raw
  is
    t_rv raw(32767);
    t_unicode pls_integer;
  begin
    if g_current_font is null
    then
      set_font( 'helvetica' );
    end if;
    if g_fonts( g_current_font ).cid
    then
      for i in 1 .. length( p_txt )
      loop
        t_unicode := utl_raw.cast_to_binary_integer( utl_raw.convert( utl_raw.cast_to_raw( substr( p_txt, i, 1 ) )
                                                                    , 'AMERICAN_AMERICA.AL16UTF16'
                                                                    , sys_context( 'userenv', 'LANGUAGE' )  -- ???? font characterset ?????
                                                                    )
                                                 );
        if g_fonts( g_current_font ).flags = 4 -- a symbolic font
        then
-- assume code 32, space maps to the first code from the font
          t_unicode := g_fonts( g_current_font ).code2glyph.first + t_unicode - 32;
        end if;
        if g_fonts( g_current_font ).code2glyph.exists( t_unicode )
        then
          g_fonts( g_current_font ).used_chars( g_fonts( g_current_font ).code2glyph( t_unicode ) ) := 0;
          t_rv := utl_raw.concat( t_rv
                                , utl_raw.cast_to_raw( to_char( g_fonts( g_current_font ).code2glyph( t_unicode ), 'FM0XXX' ) )
                                );
        else
          t_rv := utl_raw.concat( t_rv, utl_raw.cast_to_raw( '0000' ) );
        end if;
      end loop;
      t_rv := utl_raw.concat( utl_raw.cast_to_raw( '<' )
                            , t_rv
                            , utl_raw.cast_to_raw( '>' )
                            );
    else
      t_rv := utl_raw.convert( utl_raw.cast_to_raw( p_txt )
                             , g_fonts( g_current_font ).charset
                             , sys_context( 'userenv', 'LANGUAGE' )
                             );
      for i in 1 .. utl_raw.length( t_rv )
      loop
        g_fonts( g_current_font ).used_chars( raw2num( t_rv, i, 1 ) ) := 0;
      end loop;
      t_rv := utl_raw.concat( utl_raw.cast_to_raw( '(' )
                            , pdf_string( t_rv )
                            , utl_raw.cast_to_raw( ')' )
                            );
    end if;
    return t_rv;
  end;
--
  procedure put_raw( p_x number, p_y number, p_txt raw, p_degrees_rotation number := null )
  is
    c_pi constant number := 3.14159265358979323846264338327950288419716939937510;
    t_tmp varchar2(32767);
    t_sin number;
    t_cos number;
  begin
    t_tmp := to_char_round( p_x ) || ' ' || to_char_round( p_y );
    if p_degrees_rotation is null
    then
      t_tmp := t_tmp || ' Td ';
    else
      t_sin := sin( p_degrees_rotation / 180 * c_pi );
      t_cos := cos( p_degrees_rotation / 180 * c_pi );
      t_tmp := to_char_round( t_cos, 5 ) || ' ' || t_tmp;
      t_tmp := to_char_round( - t_sin, 5 ) || ' ' || t_tmp;
      t_tmp := to_char_round( t_sin, 5 ) || ' ' || t_tmp;
      t_tmp := to_char_round( t_cos, 5 ) || ' ' || t_tmp;
      t_tmp := t_tmp || ' Tm ';
    end if;
    raw2page( utl_raw.concat( utl_raw.cast_to_raw( 'BT ' || t_tmp )
                            , p_txt
                            , utl_raw.cast_to_raw( ' Tj ET' )
                            )
              );
  end;
--
  procedure put_txt( p_x number, p_y number, p_txt varchar2, p_degrees_rotation number := null )
  is
  begin
    if p_txt is not null
    then
      put_raw( p_x, p_y, txt2raw( p_txt ), p_degrees_rotation );
    end if;
  end;
--
  function str_len( p_txt in varchar2 )
  return number
  is
    t_width number;
    t_char pls_integer;
    t_rtxt raw(32767);
    t_tmp number;
    t_font tp_font;
  begin
    if p_txt is null
    then
      return 0;
    end if;
--
    t_width := 0;
    t_font := g_fonts( g_current_font );
    if t_font.cid
    then
      t_rtxt := utl_raw.convert( utl_raw.cast_to_raw( p_txt )
                               , 'AMERICAN_AMERICA.AL16UTF16' -- 16 bit font => 2 bytes per char
                               , sys_context( 'userenv', 'LANGUAGE' )  -- ???? font characterset ?????
                               );
      for i in 1 .. utl_raw.length( t_rtxt ) / 2
      loop
        t_char := to_number( utl_raw.substr( t_rtxt, i * 2 - 1, 2 ), 'xxxx' );
        if t_font.flags = 4 -- a symbolic font
        then
-- assume code 32, space maps to the first code from the font
          t_char := t_font.code2glyph.first + t_char - 32;
        end if;
        if (   t_font.code2glyph.exists( t_char )
           and t_font.hmetrics.exists( t_font.code2glyph( t_char ) )
           )
        then
          t_tmp := t_font.hmetrics( t_font.code2glyph( t_char ) );
        else
          t_tmp := t_font.hmetrics( t_font.hmetrics.last() );
        end if;
        t_width := t_width + t_tmp;
      end loop;
      t_width := t_width * t_font.unit_norm;
      t_width := t_width * t_font.fontsize / 1000;
    else
      t_rtxt := utl_raw.convert( utl_raw.cast_to_raw( p_txt )
                               , t_font.charset  -- should be an 8 bit font
                               , sys_context( 'userenv', 'LANGUAGE' )
                               );
      for i in 1 .. utl_raw.length( t_rtxt )
      loop
        t_char := to_number( utl_raw.substr( t_rtxt, i, 1 ), 'xx' );
        t_width := t_width + t_font.char_width_tab( t_char );
      end loop;
      t_width := t_width * t_font.fontsize / 1000;
    end if;
    return t_width;
  end;
--
  procedure write
    ( p_txt in varchar2
    , p_x in number := null
    , p_y in number := null
    , p_line_height in number := null
    , p_start in number := null  -- left side of the available text box
    , p_width in number := null  -- width of the available text box
    , p_alignment in varchar2 := null
    )
  is
    t_line_height number;
    t_x number;
    t_y number;
    t_start number;
    t_width number;
    t_len number;
    t_cnt pls_integer;
    t_ind pls_integer;
    t_alignment varchar2(100);
  begin
    if p_txt is null
    then
      return;
    end if;
--
    if g_current_font is null
    then
      set_font( 'helvetica' );
    end if;
--
    t_line_height := nvl( p_line_height, g_fonts( g_current_font ).fontsize );
    if (  t_line_height < g_fonts( g_current_font ).fontsize
       or t_line_height > ( g_settings.page_height - g_settings.margin_top - t_line_height ) / 4
       )
    then
      t_line_height := g_fonts( g_current_font ).fontsize;
    end if;
    t_start := nvl( p_start, g_settings.margin_left );
    if (  t_start < g_settings.margin_left
       or t_start > g_settings.page_width - g_settings.margin_right - g_settings.margin_left
       )
    then
      t_start := g_settings.margin_left;
    end if;
    t_width := nvl( p_width
                  , g_settings.page_width - g_settings.margin_right - g_settings.margin_left
                  );
    if (  t_width < str_len( '   ' )
       or t_width > g_settings.page_width - g_settings.margin_right - g_settings.margin_left
       )
    then
      t_width := g_settings.page_width - g_settings.margin_right - g_settings.margin_left;
    end if;
    t_x := coalesce( p_x, g_x, g_settings.margin_left );
    t_y := coalesce( p_y
                   , g_y
                   , g_settings.page_height - g_settings.margin_top - t_line_height
                   );
    if t_y < 0
    then
      t_y := coalesce( g_y
                     , g_settings.page_height - g_settings.margin_top - t_line_height
                     ) - t_line_height;
    end if; 
    if t_x > t_start + t_width
    then
      t_x := t_start;
      t_y := t_y - t_line_height;
    elsif t_x < t_start
    then
      t_x := t_start;
    end if;
    if t_y < g_settings.margin_bottom
    then
      new_page;
      t_x := t_start;
      t_y := g_settings.page_height - g_settings.margin_top - t_line_height;
    end if;
--
    t_ind := instr( p_txt, chr(10) );
    if t_ind > 0
    then
      g_x := t_x;
      g_y := t_y;
      write( rtrim( substr( p_txt, 1, t_ind - 1 ), chr(13) ), t_x, t_y, t_line_height, t_start, t_width, p_alignment );
      t_y := g_y - t_line_height;
      if t_y < g_settings.margin_bottom
      then
        new_page;
        t_y := g_settings.page_height - g_settings.margin_top - t_line_height;
      end if;
      g_x := t_start;
      g_y := t_y;
      write( substr( p_txt, t_ind + 1 ), t_start, t_y, t_line_height, t_start, t_width, p_alignment );
      return;
    end if;
--
    t_len := str_len( p_txt );
    if t_len <= t_width - t_x + t_start
    then
      t_alignment := lower( substr( p_alignment, 1, 100 ) );
      if instr( t_alignment, 'right' ) > 0 or instr( t_alignment, 'end' ) > 0
      then
        t_x := t_start + t_width - t_len;
      elsif instr( t_alignment, 'center' ) > 0
      then
        t_x := ( t_width + t_x + t_start - t_len ) / 2;
      end if;
      put_txt( t_x, t_y, p_txt );
      g_x := t_x + t_len + str_len( ' ' );
      g_y := t_y;
      return;
    end if;
--
    t_cnt := 0;
    while (   instr( p_txt, ' ', 1, t_cnt + 1 ) > 0
          and str_len( substr( p_txt, 1, instr( p_txt, ' ', 1, t_cnt + 1 ) - 1 ) ) <= t_width - t_x + t_start
          )
    loop
      t_cnt := t_cnt + 1;
    end loop;
    if t_cnt > 0
    then
      t_ind := instr( p_txt, ' ', 1, t_cnt );
      write( substr( p_txt, 1, t_ind - 1 ), t_x, t_y, t_line_height, t_start, t_width, p_alignment );
      t_y := t_y - t_line_height;
      if t_y < g_settings.margin_bottom
      then
        new_page;
        t_y := g_settings.page_height - g_settings.margin_top - t_line_height;
      end if;
      write( substr( p_txt, t_ind + 1 ), t_start, t_y, t_line_height, t_start, t_width, p_alignment );
      return;
    end if;
--
    if t_x > t_start and t_len < t_width
    then
      t_y := t_y - t_line_height;
      if t_y < g_settings.margin_bottom
      then
        new_page;
        t_y := g_settings.page_height - g_settings.margin_top - t_line_height;
      end if;
      write( p_txt, t_start, t_y, t_line_height, t_start, t_width, p_alignment );
    else
      if length( p_txt ) = 1
      then
        if t_x > t_start
        then
          t_y := t_y - t_line_height;
          if t_y < g_settings.margin_bottom
          then
            new_page;
            t_y := g_settings.page_height - g_settings.margin_top - t_line_height;
          end if;
        end if;
        write( p_txt, t_x, t_y, t_line_height, t_start, t_len );
      else
        t_ind := 2; -- start with 2 to make sure we get amaller string!
        while str_len( substr( p_txt, 1, t_ind ) ) <= t_width - t_x + t_start
        loop
          t_ind := t_ind + 1;
        end loop;
        write( substr( p_txt, 1, t_ind - 1 ), t_x, t_y, t_line_height, t_start, t_width, p_alignment );
        t_y := t_y - t_line_height;
        if t_y < g_settings.margin_bottom
        then
          new_page;
          t_y := g_settings.page_height - g_settings.margin_top - t_line_height;
        end if;
        write( substr( p_txt, t_ind ), t_start, t_y, t_line_height, t_start, t_width, p_alignment );
      end if;
    end if;
  end;
--
  function load_ttf_font
    ( p_font blob
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    , p_offset number := 1
    )
  return pls_integer
  is
    this_font tp_font;
    type tp_font_table is record
      ( offset pls_integer
      , length pls_integer
      );
    type tp_tables is table of tp_font_table index by varchar2(4);
    t_tables tp_tables;
    t_tag varchar2(4);
    t_blob blob;
    t_offset pls_integer;
    nr_hmetrics pls_integer;
    subtype tp_glyphname is varchar2(250);
    type tp_glyphnames is table of tp_glyphname index by pls_integer;
    t_glyphnames tp_glyphnames;
    t_glyph2name tp_pls_tab;
    t_font_ind pls_integer;
  begin
    if dbms_lob.substr( p_font, 4, p_offset ) != hextoraw( '00010000' ) --  OpenType Font
    then
      return null;
    end if;
    for i in 1 .. blob2num( p_font, 2, p_offset + 4 )
    loop
      t_tag :=
        utl_raw.cast_to_varchar2( dbms_lob.substr( p_font, 4, p_offset - 4 + i * 16 ) );
      t_tables( t_tag ).offset := blob2num( p_font, 4, p_offset + 4 + i * 16 ) + 1;
      t_tables( t_tag ).length := blob2num( p_font, 4, p_offset + 8 + i * 16 );
    end loop;
--
    if (  not t_tables.exists( 'cmap' )
       or not t_tables.exists( 'glyf' )
       or not t_tables.exists( 'head' )
       or not t_tables.exists( 'hhea' )
       or not t_tables.exists( 'hmtx' )
       or not t_tables.exists( 'loca' )
       or not t_tables.exists( 'maxp' )
       or not t_tables.exists( 'name' )
       or not t_tables.exists( 'post' )
       )
    then
      return null;
    end if;
--
    dbms_lob.createtemporary( t_blob, true );
    dbms_lob.copy( t_blob, p_font, t_tables( 'maxp' ).length, 1, t_tables( 'maxp' ).offset );
    this_font.numGlyphs := blob2num( t_blob, 2, 5 );
--
    dbms_lob.copy( t_blob, p_font, t_tables( 'cmap' ).length, 1, t_tables( 'cmap' ).offset );
    for i in 0 .. blob2num( t_blob, 2, 3 ) - 1
    loop
      if (   dbms_lob.substr( t_blob, 2, 5 + i * 8 ) = hextoraw( '0003' ) -- Windows
         and dbms_lob.substr( t_blob, 2, 5 + i * 8 + 2 )
               in ( hextoraw( '0000' ) -- Symbol
                  , hextoraw( '0001' ) -- Unicode BMP (UCS-2)
                  )
         )
      then
        if dbms_lob.substr( t_blob, 2, 5 + i * 8 + 2 ) = hextoraw( '0000' ) -- Symbol
        then
          this_font.flags := 4; -- symbolic
        else
          this_font.flags := 32; -- non-symbolic
        end if;
        t_offset := blob2num( t_blob, 4, 5 + i * 8 + 4 ) + 1;
        if dbms_lob.substr( t_blob, 2, t_offset ) != hextoraw( '0004' )
        then
          return null;
        end if;
        declare
          t_seg_cnt pls_integer;
          t_end_offs pls_integer;
          t_start_offs pls_integer;
          t_idDelta_offs pls_integer;
          t_idRangeOffset_offs pls_integer;
          t_tmp pls_integer;
          t_start pls_integer;
        begin
          t_seg_cnt := blob2num( t_blob, 2, t_offset + 6 ) / 2;
          t_end_offs := t_offset + 14;
          t_start_offs := t_end_offs + t_seg_cnt * 2 + 2;
          t_idDelta_offs := t_start_offs + t_seg_cnt * 2;
          t_idRangeOffset_offs := t_idDelta_offs + t_seg_cnt * 2;
          for seg in 0 .. t_seg_cnt - 1
          loop
            t_tmp := blob2num( t_blob, 2, t_idRangeOffset_offs + seg * 2 );
            if t_tmp = 0
            then
              t_tmp := blob2num( t_blob, 2, t_idDelta_offs + seg * 2 );
              for c in blob2num( t_blob, 2, t_start_offs + seg * 2 )
                    .. blob2num( t_blob, 2, t_end_offs + seg * 2 )
              loop
                this_font.code2glyph( c ) := mod( c + t_tmp, 65536 );
              end loop;
            else
              t_start := blob2num( t_blob, 2, t_start_offs + seg * 2 );
              for c in t_start .. blob2num( t_blob, 2, t_end_offs + seg * 2 )
              loop
                this_font.code2glyph( c ) := blob2num( t_blob, 2, t_idRangeOffset_offs + t_tmp + ( seg + c - t_start ) * 2 );
              end loop;
            end if;
          end loop;
        end;
        exit;
      end if;
    end loop;
--
    t_glyphnames( 0 ) := '.notdef';
    t_glyphnames( 1 ) := '.null';
    t_glyphnames( 2 ) := 'nonmarkingreturn';
    t_glyphnames( 3 ) := 'space';
    t_glyphnames( 4 ) := 'exclam';
    t_glyphnames( 5 ) := 'quotedbl';
    t_glyphnames( 6 ) := 'numbersign';
    t_glyphnames( 7 ) := 'dollar';
    t_glyphnames( 8 ) := 'percent';
    t_glyphnames( 9 ) := 'ampersand';
    t_glyphnames( 10 ) := 'quotesingle';
    t_glyphnames( 11 ) := 'parenleft';
    t_glyphnames( 12 ) := 'parenright';
    t_glyphnames( 13 ) := 'asterisk';
    t_glyphnames( 14 ) := 'plus';
    t_glyphnames( 15 ) := 'comma';
    t_glyphnames( 16 ) := 'hyphen';
    t_glyphnames( 17 ) := 'period';
    t_glyphnames( 18 ) := 'slash';
    t_glyphnames( 19 ) := 'zero';
    t_glyphnames( 20 ) := 'one';
    t_glyphnames( 21 ) := 'two';
    t_glyphnames( 22 ) := 'three';
    t_glyphnames( 23 ) := 'four';
    t_glyphnames( 24 ) := 'five';
    t_glyphnames( 25 ) := 'six';
    t_glyphnames( 26 ) := 'seven';
    t_glyphnames( 27 ) := 'eight';
    t_glyphnames( 28 ) := 'nine';
    t_glyphnames( 29 ) := 'colon';
    t_glyphnames( 30 ) := 'semicolon';
    t_glyphnames( 31 ) := 'less';
    t_glyphnames( 32 ) := 'equal';
    t_glyphnames( 33 ) := 'greater';
    t_glyphnames( 34 ) := 'question';
    t_glyphnames( 35 ) := 'at';
    t_glyphnames( 36 ) := 'A';
    t_glyphnames( 37 ) := 'B';
    t_glyphnames( 38 ) := 'C';
    t_glyphnames( 39 ) := 'D';
    t_glyphnames( 40 ) := 'E';
    t_glyphnames( 41 ) := 'F';
    t_glyphnames( 42 ) := 'G';
    t_glyphnames( 43 ) := 'H';
    t_glyphnames( 44 ) := 'I';
    t_glyphnames( 45 ) := 'J';
    t_glyphnames( 46 ) := 'K';
    t_glyphnames( 47 ) := 'L';
    t_glyphnames( 48 ) := 'M';
    t_glyphnames( 49 ) := 'N';
    t_glyphnames( 50 ) := 'O';
    t_glyphnames( 51 ) := 'P';
    t_glyphnames( 52 ) := 'Q';
    t_glyphnames( 53 ) := 'R';
    t_glyphnames( 54 ) := 'S';
    t_glyphnames( 55 ) := 'T';
    t_glyphnames( 56 ) := 'U';
    t_glyphnames( 57 ) := 'V';
    t_glyphnames( 58 ) := 'W';
    t_glyphnames( 59 ) := 'X';
    t_glyphnames( 60 ) := 'Y';
    t_glyphnames( 61 ) := 'Z';
    t_glyphnames( 62 ) := 'bracketleft';
    t_glyphnames( 63 ) := 'backslash';
    t_glyphnames( 64 ) := 'bracketright';
    t_glyphnames( 65 ) := 'asciicircum';
    t_glyphnames( 66 ) := 'underscore';
    t_glyphnames( 67 ) := 'grave';
    t_glyphnames( 68 ) := 'a';
    t_glyphnames( 69 ) := 'b';
    t_glyphnames( 70 ) := 'c';
    t_glyphnames( 71 ) := 'd';
    t_glyphnames( 72 ) := 'e';
    t_glyphnames( 73 ) := 'f';
    t_glyphnames( 74 ) := 'g';
    t_glyphnames( 75 ) := 'h';
    t_glyphnames( 76 ) := 'i';
    t_glyphnames( 77 ) := 'j';
    t_glyphnames( 78 ) := 'k';
    t_glyphnames( 79 ) := 'l';
    t_glyphnames( 80 ) := 'm';
    t_glyphnames( 81 ) := 'n';
    t_glyphnames( 82 ) := 'o';
    t_glyphnames( 83 ) := 'p';
    t_glyphnames( 84 ) := 'q';
    t_glyphnames( 85 ) := 'r';
    t_glyphnames( 86 ) := 's';
    t_glyphnames( 87 ) := 't';
    t_glyphnames( 88 ) := 'u';
    t_glyphnames( 89 ) := 'v';
    t_glyphnames( 90 ) := 'w';
    t_glyphnames( 91 ) := 'x';
    t_glyphnames( 92 ) := 'y';
    t_glyphnames( 93 ) := 'z';
    t_glyphnames( 94 ) := 'braceleft';
    t_glyphnames( 95 ) := 'bar';
    t_glyphnames( 96 ) := 'braceright';
    t_glyphnames( 97 ) := 'asciitilde';
    t_glyphnames( 98 ) := 'Adieresis';
    t_glyphnames( 99 ) := 'Aring';
    t_glyphnames( 100 ) := 'Ccedilla';
    t_glyphnames( 101 ) := 'Eacute';
    t_glyphnames( 102 ) := 'Ntilde';
    t_glyphnames( 103 ) := 'Odieresis';
    t_glyphnames( 104 ) := 'Udieresis';
    t_glyphnames( 105 ) := 'aacute';
    t_glyphnames( 106 ) := 'agrave';
    t_glyphnames( 107 ) := 'acircumflex';
    t_glyphnames( 108 ) := 'adieresis';
    t_glyphnames( 109 ) := 'atilde';
    t_glyphnames( 110 ) := 'aring';
    t_glyphnames( 111 ) := 'ccedilla';
    t_glyphnames( 112 ) := 'eacute';
    t_glyphnames( 113 ) := 'egrave';
    t_glyphnames( 114 ) := 'ecircumflex';
    t_glyphnames( 115 ) := 'edieresis';
    t_glyphnames( 116 ) := 'iacute';
    t_glyphnames( 117 ) := 'igrave';
    t_glyphnames( 118 ) := 'icircumflex';
    t_glyphnames( 119 ) := 'idieresis';
    t_glyphnames( 120 ) := 'ntilde';
    t_glyphnames( 121 ) := 'oacute';
    t_glyphnames( 122 ) := 'ograve';
    t_glyphnames( 123 ) := 'ocircumflex';
    t_glyphnames( 124 ) := 'odieresis';
    t_glyphnames( 125 ) := 'otilde';
    t_glyphnames( 126 ) := 'uacute';
    t_glyphnames( 127 ) := 'ugrave';
    t_glyphnames( 128 ) := 'ucircumflex';
    t_glyphnames( 129 ) := 'udieresis';
    t_glyphnames( 130 ) := 'dagger';
    t_glyphnames( 131 ) := 'degree';
    t_glyphnames( 132 ) := 'cent';
    t_glyphnames( 133 ) := 'sterling';
    t_glyphnames( 134 ) := 'section';
    t_glyphnames( 135 ) := 'bullet';
    t_glyphnames( 136 ) := 'paragraph';
    t_glyphnames( 137 ) := 'germandbls';
    t_glyphnames( 138 ) := 'registered';
    t_glyphnames( 139 ) := 'copyright';
    t_glyphnames( 140 ) := 'trademark';
    t_glyphnames( 141 ) := 'acute';
    t_glyphnames( 142 ) := 'dieresis';
    t_glyphnames( 143 ) := 'notequal';
    t_glyphnames( 144 ) := 'AE';
    t_glyphnames( 145 ) := 'Oslash';
    t_glyphnames( 146 ) := 'infinity';
    t_glyphnames( 147 ) := 'plusminus';
    t_glyphnames( 148 ) := 'lessequal';
    t_glyphnames( 149 ) := 'greaterequal';
    t_glyphnames( 150 ) := 'yen';
    t_glyphnames( 151 ) := 'mu';
    t_glyphnames( 152 ) := 'partialdiff';
    t_glyphnames( 153 ) := 'summation';
    t_glyphnames( 154 ) := 'product';
    t_glyphnames( 155 ) := 'pi';
    t_glyphnames( 156 ) := 'integral';
    t_glyphnames( 157 ) := 'ordfeminine';
    t_glyphnames( 158 ) := 'ordmasculine';
    t_glyphnames( 159 ) := 'Omega';
    t_glyphnames( 160 ) := 'ae';
    t_glyphnames( 161 ) := 'oslash';
    t_glyphnames( 162 ) := 'questiondown';
    t_glyphnames( 163 ) := 'exclamdown';
    t_glyphnames( 164 ) := 'logicalnot';
    t_glyphnames( 165 ) := 'radical';
    t_glyphnames( 166 ) := 'florin';
    t_glyphnames( 167 ) := 'approxequal';
    t_glyphnames( 168 ) := 'Delta';
    t_glyphnames( 169 ) := 'guillemotleft';
    t_glyphnames( 170 ) := 'guillemotright';
    t_glyphnames( 171 ) := 'ellipsis';
    t_glyphnames( 172 ) := 'nonbreakingspace';
    t_glyphnames( 173 ) := 'Agrave';
    t_glyphnames( 174 ) := 'Atilde';
    t_glyphnames( 175 ) := 'Otilde';
    t_glyphnames( 176 ) := 'OE';
    t_glyphnames( 177 ) := 'oe';
    t_glyphnames( 178 ) := 'endash';
    t_glyphnames( 179 ) := 'emdash';
    t_glyphnames( 180 ) := 'quotedblleft';
    t_glyphnames( 181 ) := 'quotedblright';
    t_glyphnames( 182 ) := 'quoteleft';
    t_glyphnames( 183 ) := 'quoteright';
    t_glyphnames( 184 ) := 'divide';
    t_glyphnames( 185 ) := 'lozenge';
    t_glyphnames( 186 ) := 'ydieresis';
    t_glyphnames( 187 ) := 'Ydieresis';
    t_glyphnames( 188 ) := 'fraction';
    t_glyphnames( 189 ) := 'currency';
    t_glyphnames( 190 ) := 'guilsinglleft';
    t_glyphnames( 191 ) := 'guilsinglright';
    t_glyphnames( 192 ) := 'fi';
    t_glyphnames( 193 ) := 'fl';
    t_glyphnames( 194 ) := 'daggerdbl';
    t_glyphnames( 195 ) := 'periodcentered';
    t_glyphnames( 196 ) := 'quotesinglbase';
    t_glyphnames( 197 ) := 'quotedblbase';
    t_glyphnames( 198 ) := 'perthousand';
    t_glyphnames( 199 ) := 'Acircumflex';
    t_glyphnames( 200 ) := 'Ecircumflex';
    t_glyphnames( 201 ) := 'Aacute';
    t_glyphnames( 202 ) := 'Edieresis';
    t_glyphnames( 203 ) := 'Egrave';
    t_glyphnames( 204 ) := 'Iacute';
    t_glyphnames( 205 ) := 'Icircumflex';
    t_glyphnames( 206 ) := 'Idieresis';
    t_glyphnames( 207 ) := 'Igrave';
    t_glyphnames( 208 ) := 'Oacute';
    t_glyphnames( 209 ) := 'Ocircumflex';
    t_glyphnames( 210 ) := 'apple';
    t_glyphnames( 211 ) := 'Ograve';
    t_glyphnames( 212 ) := 'Uacute';
    t_glyphnames( 213 ) := 'Ucircumflex';
    t_glyphnames( 214 ) := 'Ugrave';
    t_glyphnames( 215 ) := 'dotlessi';
    t_glyphnames( 216 ) := 'circumflex';
    t_glyphnames( 217 ) := 'tilde';
    t_glyphnames( 218 ) := 'macron';
    t_glyphnames( 219 ) := 'breve';
    t_glyphnames( 220 ) := 'dotaccent';
    t_glyphnames( 221 ) := 'ring';
    t_glyphnames( 222 ) := 'cedilla';
    t_glyphnames( 223 ) := 'hungarumlaut';
    t_glyphnames( 224 ) := 'ogonek';
    t_glyphnames( 225 ) := 'caron';
    t_glyphnames( 226 ) := 'Lslash';
    t_glyphnames( 227 ) := 'lslash';
    t_glyphnames( 228 ) := 'Scaron';
    t_glyphnames( 229 ) := 'scaron';
    t_glyphnames( 230 ) := 'Zcaron';
    t_glyphnames( 231 ) := 'zcaron';
    t_glyphnames( 232 ) := 'brokenbar';
    t_glyphnames( 233 ) := 'Eth';
    t_glyphnames( 234 ) := 'eth';
    t_glyphnames( 235 ) := 'Yacute';
    t_glyphnames( 236 ) := 'yacute';
    t_glyphnames( 237 ) := 'Thorn';
    t_glyphnames( 238 ) := 'thorn';
    t_glyphnames( 239 ) := 'minus';
    t_glyphnames( 240 ) := 'multiply';
    t_glyphnames( 241 ) := 'onesuperior';
    t_glyphnames( 242 ) := 'twosuperior';
    t_glyphnames( 243 ) := 'threesuperior';
    t_glyphnames( 244 ) := 'onehalf';
    t_glyphnames( 245 ) := 'onequarter';
    t_glyphnames( 246 ) := 'threequarters';
    t_glyphnames( 247 ) := 'franc';
    t_glyphnames( 248 ) := 'Gbreve';
    t_glyphnames( 249 ) := 'gbreve';
    t_glyphnames( 250 ) := 'Idotaccent';
    t_glyphnames( 251 ) := 'Scedilla';
    t_glyphnames( 252 ) := 'scedilla';
    t_glyphnames( 253 ) := 'Cacute';
    t_glyphnames( 254 ) := 'cacute';
    t_glyphnames( 255 ) := 'Ccaron';
    t_glyphnames( 256 ) := 'ccaron';
    t_glyphnames( 257 ) := 'dcroat';
--
    dbms_lob.copy( t_blob, p_font, t_tables( 'post' ).length, 1, t_tables( 'post' ).offset );
    this_font.italic_angle := to_short( dbms_lob.substr( t_blob, 2, 5 ) )
                            + to_short( dbms_lob.substr( t_blob, 2, 7 ) ) / 65536;
    case rawtohex( dbms_lob.substr( t_blob, 4, 1 ) )
      when '00010000'
      then
        for g in 0 .. 257
        loop
          t_glyph2name( g ) := g;
        end loop;
      when '00020000'
      then
        t_offset := blob2num( t_blob, 2, 33 ) * 2 + 35;
        while nvl( blob2num( t_blob, 1, t_offset ), 0 ) > 0
        loop
          t_glyphnames( t_glyphnames.count ) := utl_raw.cast_to_varchar2( dbms_lob.substr( t_blob, blob2num( t_blob, 1, t_offset ), t_offset + 1 ) );
          t_offset := t_offset + blob2num( t_blob, 1, t_offset ) + 1;
        end loop;
        for g in 0 .. blob2num( t_blob, 2, 33 ) - 1
        loop
          t_glyph2name( g ) := blob2num( t_blob, 2, 35 + 2 * g );
        end loop;
      when '00025000'
      then
        for g in 0 .. blob2num( t_blob, 2, 33 ) - 1
        loop
          t_offset := blob2num( t_blob, 1, 35 + g );
          if t_offset > 127
          then
            t_glyph2name( g ) := g - t_offset;
          else
            t_glyph2name( g ) := g + t_offset;
          end if;
        end loop;
      when '00030000'
      then
        t_glyphnames.delete;
      else
dbms_output.put_line( 'no post ' || dbms_lob.substr( t_blob, 4, 1 ) );
    end case;
--
    dbms_lob.copy( t_blob, p_font, t_tables( 'head' ).length, 1, t_tables( 'head' ).offset );
    if dbms_lob.substr( t_blob, 4, 13 ) = hextoraw( '5F0F3CF5' )  -- magic
    then
      declare
        t_tmp pls_integer := blob2num( t_blob, 2, 45 );
      begin
        if bitand( t_tmp, 1 ) = 1
        then
          this_font.style := 'B';
        end if;
        if bitand( t_tmp, 2 ) = 2
        then
          this_font.style := this_font.style || 'I';
          this_font.flags := this_font.flags + 64;
        end if;
        this_font.style := nvl( this_font.style, 'N' );
        this_font.unit_norm := 1000 / blob2num( t_blob, 2, 19 );
        this_font.bb_xmin := to_short( dbms_lob.substr( t_blob, 2, 37 ), this_font.unit_norm );
        this_font.bb_ymin := to_short( dbms_lob.substr( t_blob, 2, 39 ), this_font.unit_norm );
        this_font.bb_xmax := to_short( dbms_lob.substr( t_blob, 2, 41 ), this_font.unit_norm );
        this_font.bb_ymax := to_short( dbms_lob.substr( t_blob, 2, 43 ), this_font.unit_norm );
        this_font.indexToLocFormat := blob2num( t_blob, 2, 51 ); -- 0 for short offsets, 1 for long
      end;
    end if;
--
    dbms_lob.copy( t_blob, p_font, t_tables( 'hhea' ).length, 1, t_tables( 'hhea' ).offset );
    if dbms_lob.substr( t_blob, 4, 1 ) = hextoraw( '00010000' ) -- version 1.0
    then
      this_font.ascent := to_short( dbms_lob.substr( t_blob, 2, 5 ), this_font.unit_norm );
      this_font.descent := to_short( dbms_lob.substr( t_blob, 2, 7 ), this_font.unit_norm );
      this_font.capheight := this_font.ascent;
      nr_hmetrics := blob2num( t_blob, 2, 35 );
    end if;
--
    dbms_lob.copy( t_blob, p_font, t_tables( 'hmtx' ).length, 1, t_tables( 'hmtx' ).offset );
    for j in 0 .. nr_hmetrics - 1
    loop
      this_font.hmetrics( j ) := blob2num( t_blob, 2, 1 + 4 * j );
    end loop;
--
    dbms_lob.copy( t_blob, p_font, t_tables( 'name' ).length, 1, t_tables( 'name' ).offset );
    if dbms_lob.substr( t_blob, 2, 1 ) = hextoraw( '0000' ) -- format 0
    then
      t_offset := blob2num( t_blob, 2, 5 ) + 1;
      for j in 0 .. blob2num( t_blob, 2, 3 ) - 1
      loop
        if (   dbms_lob.substr( t_blob, 2, 7  + j * 12 ) = hextoraw( '0003' ) -- Windows
           and dbms_lob.substr( t_blob, 2, 11 + j * 12 ) = hextoraw( '0409' ) -- English United States
           )
        then
          case rawtohex( dbms_lob.substr( t_blob, 2, 13 + j * 12 ) )
            when '0001'
            then
              this_font.family := utl_i18n.raw_to_char( dbms_lob.substr( t_blob, blob2num( t_blob, 2, 15 + j * 12 ), t_offset + blob2num( t_blob, 2, 17 + j * 12 ) ), 'AL16UTF16' );
            when '0006'
            then
              this_font.name := utl_i18n.raw_to_char( dbms_lob.substr( t_blob, blob2num( t_blob, 2, 15 + j * 12 ), t_offset + blob2num( t_blob, 2, 17 + j * 12 ) ), 'AL16UTF16' );
            else
              null;
          end case;
        end if;
      end loop;
    end if;
--
    if this_font.italic_angle != 0
    then
      this_font.flags := this_font.flags + 64;
    end if;
    this_font.subtype := 'TrueType';
    this_font.stemv := 50;
    this_font.family := lower( this_font.family );
    this_font.encoding := utl_i18n.map_charset( p_encoding
                                              , utl_i18n.generic_context
                                              , utl_i18n.iana_to_oracle
                                              );
    this_font.encoding := nvl( this_font.encoding, upper( p_encoding ) );
    this_font.charset := sys_context( 'userenv', 'LANGUAGE' );
    this_font.charset := substr( this_font.charset
                               , 1
                               , instr( this_font.charset, '.' )
                               ) || this_font.encoding;
    this_font.cid := upper( p_encoding ) in ( 'CID', 'AL16UTF16', 'UTF', 'UNICODE' );
    this_font.fontname := this_font.name;
    this_font.compress_font := p_compress;
--
    if ( p_embed or this_font.cid ) and t_tables.exists( 'OS/2' )
    then
      dbms_lob.copy( t_blob, p_font, t_tables( 'OS/2' ).length, 1, t_tables( 'OS/2' ).offset );
      if blob2num( t_blob, 2, 9 ) != 2
      then
        this_font.fontfile2 := p_font;
        this_font.ttf_offset := p_offset;
        this_font.name := dbms_random.string( 'u', 6 ) || '+' || this_font.name;
--
        t_blob := dbms_lob.substr( p_font, t_tables( 'loca' ).length, t_tables( 'loca' ).offset );
        declare
          t_size pls_integer := 2 + this_font.indexToLocFormat * 2; -- 0 for short offsets, 1 for long
        begin
          for i in 0 .. this_font.numGlyphs
          loop
            this_font.loca( i ) := blob2num( t_blob, t_size, 1 + i * t_size );
          end loop;
        end;
      end if;
    end if;
--
    if not this_font.cid
    then
      if this_font.flags = 4 -- a symbolic font
      then
        declare
          t_real pls_integer;
        begin
          for t_code in 32 .. 255
          loop
            t_real := this_font.code2glyph.first + t_code - 32; -- assume code 32, space maps to the first code from the font
            if this_font.code2glyph.exists( t_real )
            then
              this_font.first_char := least( nvl( this_font.first_char, 255 ), t_code );
              this_font.last_char := t_code;
              if this_font.hmetrics.exists( this_font.code2glyph( t_real ) )
              then
                this_font.char_width_tab( t_code ) := trunc( this_font.hmetrics( this_font.code2glyph( t_real ) ) * this_font.unit_norm );
              else
                this_font.char_width_tab( t_code ) := trunc( this_font.hmetrics( this_font.hmetrics.last() ) * this_font.unit_norm );
              end if;
            else
              this_font.char_width_tab( t_code ) := trunc( this_font.hmetrics( 0 ) * this_font.unit_norm );
            end if;
          end loop;
        end;
      else
        declare
          t_unicode pls_integer;
          t_prv_diff pls_integer;
          t_utf16_charset varchar2(1000);
          t_winansi_charset varchar2(1000);
          t_glyphname tp_glyphname;
        begin
          t_prv_diff := -1;
          t_utf16_charset := substr( this_font.charset, 1, instr( this_font.charset, '.' ) ) || 'AL16UTF16';
          t_winansi_charset := substr( this_font.charset, 1, instr( this_font.charset, '.' ) ) || 'WE8MSWIN1252';
          for t_code in 32 .. 255
          loop
            t_unicode := utl_raw.cast_to_binary_integer( utl_raw.convert( hextoraw( to_char( t_code, 'fm0x' ) )
                                                                        , t_utf16_charset
                                                                        , this_font.charset
                                                                        )
                                                       );
            t_glyphname := '';
            this_font.char_width_tab( t_code ) := trunc( this_font.hmetrics( this_font.hmetrics.last() ) * this_font.unit_norm );
            if this_font.code2glyph.exists( t_unicode )
            then
              this_font.first_char := least( nvl( this_font.first_char, 255 ), t_code );
              this_font.last_char := t_code;
              if this_font.hmetrics.exists( this_font.code2glyph( t_unicode ) )
              then
                this_font.char_width_tab( t_code ) := trunc( this_font.hmetrics( this_font.code2glyph( t_unicode ) ) * this_font.unit_norm );
              end if;
              if t_glyph2name.exists( this_font.code2glyph( t_unicode ) )
              then
                if t_glyphnames.exists( t_glyph2name( this_font.code2glyph( t_unicode ) ) )
                then
                  t_glyphname := t_glyphnames( t_glyph2name( this_font.code2glyph( t_unicode ) ) );
                end if;
              end if;
            end if;
--
            if (   t_glyphname is not null
               and t_unicode != utl_raw.cast_to_binary_integer( utl_raw.convert( hextoraw( to_char( t_code, 'fm0x' ) )
                                                                               , t_winansi_charset
                                                                               , this_font.charset
                                                                               )
                                                              )
               )
            then
              this_font.diff := this_font.diff || case when t_prv_diff != t_code - 1 then ' ' || t_code end || ' /' || t_glyphname;
              t_prv_diff := t_code;
            end if;
          end loop;
        end;
        if this_font.diff is not null
        then
          this_font.diff := '/Differences [' || this_font.diff || ']';
        end if;
      end if;
    end if;
--
    t_font_ind := g_fonts.count( ) + 1; 
    g_fonts( t_font_ind ) := this_font;
/*
--
dbms_output.put_line( this_font.fontname || ' ' || this_font.family || ' ' || this_font.style
|| ' ' || this_font.flags
|| ' ' || this_font.code2glyph.first
|| ' ' || this_font.code2glyph.prior( this_font.code2glyph.last )
|| ' ' || this_font.code2glyph.last
|| ' nr glyphs: ' || this_font.numGlyphs
 ); */
--
    return t_font_ind;
  end;
--
  procedure load_ttf_font
    ( p_font blob
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    , p_offset number := 1
    )
  is
    t_tmp pls_integer;
  begin
    t_tmp := load_ttf_font( p_font, p_encoding, p_embed, p_compress );
  end;
--
  function load_ttf_font
    ( p_dir varchar2 := 'MY_FONTS'
    , p_filename varchar2 := 'BAUHS93.TTF'
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    )
  return pls_integer
  is
  begin
    return load_ttf_font( file2blob( p_dir, p_filename ), p_encoding, p_embed, p_compress );
  end;
--
  procedure load_ttf_font
    ( p_dir varchar2 := 'MY_FONTS'
    , p_filename varchar2 := 'BAUHS93.TTF'
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    )
  is
  begin
    load_ttf_font( file2blob( p_dir, p_filename ), p_encoding, p_embed, p_compress );
  end;
--
  procedure load_ttc_fonts
    ( p_ttc blob
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    )
  is
    type tp_font_table is record
      ( offset pls_integer
      , length pls_integer
      );
    type tp_tables is table of tp_font_table index by varchar2(4);
    t_tables tp_tables;
    t_tag varchar2(4);
    t_blob blob;
    t_offset pls_integer;
    t_font_ind pls_integer;
  begin
    if utl_raw.cast_to_varchar2( dbms_lob.substr( p_ttc, 4, 1 ) ) != 'ttcf'
    then
      return;
    end if;
    for f in 0 .. blob2num( p_ttc, 4, 9 ) - 1
    loop
      t_font_ind := load_ttf_font( p_ttc, p_encoding, p_embed, p_compress, blob2num( p_ttc, 4, 13 + f * 4 ) + 1 );
dbms_output.put_line( t_font_ind || ' ' || g_fonts( t_font_ind ).fontname || ' ' || g_fonts( t_font_ind ).family || ' ' || g_fonts( t_font_ind ).style );
    end loop;
  end;
--
  procedure load_ttc_fonts
    ( p_dir varchar2 := 'MY_FONTS'
    , p_filename varchar2 := 'CAMBRIA.TTC'
    , p_encoding varchar2 := 'WINDOWS-1252'
    , p_embed boolean := false
    , p_compress boolean := true
    )
  is
  begin
    load_ttc_fonts( file2blob( p_dir, p_filename ), p_encoding, p_embed, p_compress );
  end;
--
  function rgb( p_hex_rgb varchar2 )
  return varchar2
  is
  begin
    return to_char_round( nvl( to_number( substr( ltrim( p_hex_rgb, '#' )
                                                , 1, 2 )
                                        , 'xx' ) / 255
                              , 0 )
                         , 5 ) || ' '
        || to_char_round( nvl(   to_number( substr( ltrim( p_hex_rgb, '#' )
                                                , 3, 2 )
                                        , 'xx' ) / 255
                              , 0 )
                         , 5 ) || ' '
        || to_char_round( nvl(   to_number( substr( ltrim( p_hex_rgb, '#' )
                                                , 5, 2 )
                                        , 'xx' ) / 255
                              , 0 )
                         , 5 ) || ' ';
  end;
--
  procedure set_color( p_rgb varchar2 := '000000', p_backgr boolean )
  is
  begin
    txt2page( rgb( p_rgb ) || case when p_backgr then 'RG' else 'rg' end );
  end;
--
  procedure set_color( p_rgb varchar2 := '000000' )
  is
  begin
    set_color( p_rgb, false );
  end;
--
  procedure set_color
    ( p_red number := 0
    , p_green number := 0
    , p_blue number := 0
    )
  is
  begin
    if (     p_red between 0 and 255
       and p_blue  between 0 and 255
       and p_green between 0 and 255
       )
    then
      set_color(  to_char( p_red, 'fm0x' )
               || to_char( p_green, 'fm0x' )
               || to_char( p_blue, 'fm0x' )
               , false
               );
    end if;
  end;
--
  procedure set_bk_color( p_rgb varchar2 := 'ffffff' )
  is
  begin
    set_color( p_rgb, true );
  end;
--
  procedure set_bk_color
    ( p_red number := 0
    , p_green number := 0
    , p_blue number := 0
    )
  is
  begin
    if (     p_red between 0 and 255
       and p_blue  between 0 and 255
       and p_green between 0 and 255
       )
    then
      set_color(  to_char( p_red, 'fm0x' )
               || to_char( p_green, 'fm0x' )
               || to_char( p_blue, 'fm0x' )
               , true
               );
    end if;
  end;
--
  procedure horizontal_line
    ( p_x number
    , p_y number
    , p_width number
    , p_line_width number := 0.5
    , p_line_color varchar2 := '000000'
    )
  is
    t_use_color boolean;
  begin
    txt2page( 'q ' || to_char_round( p_line_width, 5 ) || ' w' );
    t_use_color := substr( p_line_color
                         , -6
                         ) != '000000';
    if t_use_color
    then
      set_color( p_line_color );
      set_bk_color( p_line_color );
    else
      txt2page( '0 g' );
    end if;
    txt2page(  to_char_round( p_x, 5 ) || ' '
            || to_char_round( p_y, 5 ) || ' m '
            || to_char_round( p_x + p_width, 5 ) || ' '
            || to_char_round( p_y, 5 ) || ' l b'
            );
    txt2page( 'Q' );
  end;
--
  procedure vertical_line
    ( p_x number
    , p_y number
    , p_height number
    , p_line_width number := 0.5
    , p_line_color varchar2 := '000000'
    )
  is
    t_use_color boolean;
  begin
    txt2page( 'q ' || to_char_round( p_line_width, 5 ) || ' w' );
    t_use_color := substr( p_line_color
                         , -6
                         ) != '000000';
    if t_use_color
    then
      set_color( p_line_color );
      set_bk_color( p_line_color );
    else
      txt2page( '0 g' );
    end if;
    txt2page(  to_char_round( p_x, 5 ) || ' '
            || to_char_round( p_y, 5 ) || ' m '
            || to_char_round( p_x, 5 ) || ' '
            || to_char_round( p_y + p_height, 5 ) || ' l b'
            );
    txt2page( 'Q' );
  end;
--
  procedure rect
    ( p_x number
    , p_y number
    , p_width number
    , p_height number
    , p_line_color varchar2 := null
    , p_fill_color varchar2 := null
    , p_line_width number := 0.5
    )
  is
  begin
    txt2page( 'q' );
    if substr( p_line_color, -6 ) != substr( p_fill_color, -6 )
    then
      txt2page( to_char_round( p_line_width, 5 ) || ' w' );
    end if;
    if substr( p_line_color, -6 ) != '000000'
    then
      set_bk_color( p_line_color );
    else
      txt2page( '0 g' );
    end if;
    if p_fill_color is not null
    then
      set_color( p_fill_color );
    end if;
    txt2page(  to_char_round( p_x, 5 ) || ' ' || to_char_round( p_y, 5 ) || ' '
            || to_char_round( p_width, 5 ) || ' ' || to_char_round( p_height, 5 ) || ' re '
            || case
                 when p_fill_color is null
                 then 'S'
                 else case when p_line_color is null then 'f' else 'b' end
               end
            );
    txt2page( 'Q' );
  end;
--
  function get( p_what pls_integer )
  return number
  is
  begin
    return case p_what
             when c_get_page_width    then g_settings.page_width
             when c_get_page_height   then g_settings.page_height
             when c_get_margin_top    then g_settings.margin_top
             when c_get_margin_right  then g_settings.margin_right
             when c_get_margin_bottom then g_settings.margin_bottom
             when c_get_margin_left   then g_settings.margin_left
             when c_get_x             then g_x
             when c_get_y             then g_y
             when c_get_fontsize      then g_fonts( g_current_font ).fontsize
             when c_get_current_font  then g_current_font
           end;
  end;
--
  function parse_jpg( p_img_blob blob )
  return tp_img
  is
    buf raw(4);
    t_img tp_img;
    t_ind integer;
  begin
    if (  dbms_lob.substr( p_img_blob, 2, 1 ) != hextoraw( 'FFD8' )                                      -- SOI Start of Image
       or dbms_lob.substr( p_img_blob, 2, dbms_lob.getlength( p_img_blob ) - 1 ) != hextoraw( 'FFD9' )   -- EOI End of Image
       )
    then  -- this is not a jpg I can handle
      return null;
    end if;
--
    t_img.pixels := p_img_blob;
    t_img.type := 'jpg';
    if dbms_lob.substr( t_img.pixels, 2, 3 ) in ( hextoraw( 'FFE0' )  -- a APP0 jpg
                                                , hextoraw( 'FFE1' )  -- a APP1 jpg
                                                )
    then
      t_img.color_res := 8;
      t_img.height := 1;
      t_img.width := 1;
--
      t_ind := 3;
      t_ind := t_ind + 2 + blob2num( t_img.pixels, 2, t_ind + 2 );
      loop
        buf := dbms_lob.substr( t_img.pixels, 2, t_ind );
        exit when buf = hextoraw( 'FFDA' );  -- SOS Start of Scan
        exit when buf = hextoraw( 'FFD9' );  -- EOI End Of Image
        exit when substr( rawtohex( buf ), 1, 2 ) != 'FF';
        if rawtohex( buf ) in ( 'FFD0'                                                          -- RSTn
                              , 'FFD1', 'FFD2', 'FFD3', 'FFD4', 'FFD5', 'FFD6', 'FFD7', 'FF01'  -- TEM
                              )
        then
          t_ind := t_ind + 2;
        else
          if buf = hextoraw( 'FFC0' )       -- SOF0 (Start Of Frame 0) marker
          then
            t_img.color_res := blob2num( t_img.pixels, 1, t_ind + 4 );
            t_img.height    := blob2num( t_img.pixels, 2, t_ind + 5 );
            t_img.width     := blob2num( t_img.pixels, 2, t_ind + 7 );
          end if;
          t_ind := t_ind + 2 + blob2num( t_img.pixels, 2, t_ind + 2 );
        end if;
      end loop;
    end if;
--
    return t_img;
  end;
--
  function parse_png( p_img_blob blob )
  return tp_img
  is
    t_img tp_img;
    buf raw(32767);
    len integer;
    ind integer;
    color_type pls_integer;
  begin
    if rawtohex( dbms_lob.substr( p_img_blob, 8, 1 ) ) != '89504E470D0A1A0A'  -- not the right signature
    then
      return null;
    end if;
    dbms_lob.createtemporary( t_img.pixels, true );
    ind := 9;
    loop
      len := blob2num( p_img_blob, 4, ind );  -- length
      exit when len is null or ind > dbms_lob.getlength( p_img_blob );
      case utl_raw.cast_to_varchar2( dbms_lob.substr( p_img_blob, 4, ind + 4 ) )  -- Chunk type
        when 'IHDR'
        then
          t_img.width     := blob2num( p_img_blob, 4, ind + 8 );
          t_img.height    := blob2num( p_img_blob, 4, ind + 12 );
          t_img.color_res := blob2num( p_img_blob, 1, ind + 16 );
          color_type      := blob2num( p_img_blob, 1, ind + 17 );
          t_img.greyscale := color_type in ( 0, 4 );
        when 'PLTE'
        then
          t_img.color_tab := dbms_lob.substr( p_img_blob, len, ind + 8 );
        when 'IDAT'
        then
          dbms_lob.copy( t_img.pixels, p_img_blob, len, dbms_lob.getlength( t_img.pixels ) + 1, ind + 8 );
        when 'IEND'
        then
          exit;
        else
          null;
      end case;
      ind := ind + 4 + 4 + len + 4;  -- Length + Chunk type + Chunk data + CRC
    end loop;
--
    t_img.type := 'png';
    t_img.nr_colors := case color_type
                         when 0 then 1
                         when 2 then 3
                         when 3 then 1
                         when 4 then 2
                         else 4
                       end;
--
    return t_img;
  end;
--
  function lzw_decompress
    ( p_blob blob
    , p_bits pls_integer
    )
  return blob
  is
    powers tp_pls_tab;
--
    g_lzw_ind pls_integer;
    g_lzw_bits pls_integer;
    g_lzw_buffer pls_integer;
    g_lzw_bits_used pls_integer;
--
    type tp_lzw_dict is table of raw(1000) index by pls_integer;
    t_lzw_dict tp_lzw_dict;
    t_clr_code pls_integer;
    t_nxt_code pls_integer;
    t_new_code pls_integer;
    t_old_code pls_integer;
    t_blob blob;
--
    function get_lzw_code
    return pls_integer
    is
      t_rv pls_integer;
    begin
      while g_lzw_bits_used < g_lzw_bits
      loop
        g_lzw_ind := g_lzw_ind + 1;
        g_lzw_buffer := blob2num( p_blob, 1, g_lzw_ind ) * powers( g_lzw_bits_used ) + g_lzw_buffer;
        g_lzw_bits_used := g_lzw_bits_used + 8;
      end loop;
      t_rv := bitand( g_lzw_buffer, powers( g_lzw_bits ) - 1 );
      g_lzw_bits_used := g_lzw_bits_used - g_lzw_bits;
      g_lzw_buffer := trunc( g_lzw_buffer / powers( g_lzw_bits ) );
      return t_rv;
    end;
--
  begin
    for i in 0 .. 30
    loop
      powers( i ) := power( 2, i );
    end loop;
--
    t_clr_code := powers( p_bits - 1 );
    t_nxt_code := t_clr_code + 2;
    for i in 0 .. least( t_clr_code - 1, 255 )
    loop
      t_lzw_dict( i ) := hextoraw( to_char( i, 'fm0X' ) );
    end loop;
    dbms_lob.createtemporary( t_blob, true );
    g_lzw_ind := 0;
    g_lzw_bits := p_bits;
    g_lzw_buffer := 0;
    g_lzw_bits_used := 0;
--
    t_old_code := null;
    t_new_code := get_lzw_code( );
    loop
      case nvl( t_new_code, t_clr_code + 1 )
        when t_clr_code + 1
        then
          exit;
        when t_clr_code
        then
          t_new_code := null;
          g_lzw_bits := p_bits;
          t_nxt_code := t_clr_code + 2;
        else
          if t_new_code = t_nxt_code
          then
            t_lzw_dict( t_nxt_code ) :=
              utl_raw.concat( t_lzw_dict( t_old_code )
                            , utl_raw.substr( t_lzw_dict( t_old_code ), 1, 1 )
                            );
            dbms_lob.append( t_blob, t_lzw_dict( t_nxt_code ) );
            t_nxt_code := t_nxt_code + 1;
          elsif t_new_code > t_nxt_code
          then
            exit;
          else
            dbms_lob.append( t_blob, t_lzw_dict( t_new_code ) );
            if t_old_code is not null
            then
              t_lzw_dict( t_nxt_code ) := utl_raw.concat( t_lzw_dict( t_old_code )
                                                        , utl_raw.substr( t_lzw_dict( t_new_code ), 1, 1 )
                                                        );
              t_nxt_code := t_nxt_code + 1;
            end if;
          end if;
          if     bitand( t_nxt_code, powers( g_lzw_bits ) - 1 ) = 0
             and g_lzw_bits < 12
          then
            g_lzw_bits := g_lzw_bits + 1;
          end if;
      end case;
      t_old_code := t_new_code;
      t_new_code := get_lzw_code( );
    end loop;
    t_lzw_dict.delete;
--
    return t_blob;
  end;
--
  function parse_gif( p_img_blob blob )
  return tp_img
  is
    img tp_img;
    buf raw(4000);
    ind integer;
    t_len pls_integer;
  begin
    if dbms_lob.substr( p_img_blob, 3, 1 ) != utl_raw.cast_to_raw( 'GIF' )
    then
      return null;
    end if;
    ind := 7;
    buf := dbms_lob.substr( p_img_blob, 7, 7 );  --  Logical Screen Descriptor
    ind := ind + 7;
    img.color_res := raw2num( utl_raw.bit_and( utl_raw.substr( buf, 5, 1 ), hextoraw( '70' ) ) ) / 16 + 1;
    img.color_res := 8;
    if raw2num( buf, 5, 1 ) > 127
    then
      t_len := 3 * power( 2, raw2num( utl_raw.bit_and( utl_raw.substr( buf, 5, 1 ), hextoraw( '07' ) ) ) + 1 );
      img.color_tab := dbms_lob.substr( p_img_blob, t_len, ind  ); -- Global Color Table
      ind := ind + t_len;
    end if;
--
    loop
      case dbms_lob.substr( p_img_blob, 1, ind )
        when hextoraw( '3B' ) -- trailer
        then
          exit;
        when hextoraw( '21' ) -- extension
        then
          if dbms_lob.substr( p_img_blob, 1, ind + 1 ) = hextoraw( 'F9' )
          then -- Graphic Control Extension
            if utl_raw.bit_and( dbms_lob.substr( p_img_blob, 1, ind + 3 ), hextoraw( '01' ) ) = hextoraw( '01' )
            then -- Transparent Color Flag set
              img.transparancy_index := blob2num( p_img_blob, 1, ind + 6 );
            end if;
          end if;
          ind := ind + 2; -- skip sentinel + label
          loop
            t_len := blob2num( p_img_blob, 1, ind ); -- Block Size
            exit when t_len = 0;
            ind := ind + 1 + t_len; -- skip Block Size + Data Sub-block
          end loop;
          ind := ind + 1;           -- skip last Block Size
        when hextoraw( '2C' )       -- image
        then
          declare
            img_blob blob;
            min_code_size pls_integer;
            code_size pls_integer;
            flags raw(1);
          begin
            img.width := utl_raw.cast_to_binary_integer( dbms_lob.substr( p_img_blob, 2, ind + 5 )
                                                       , utl_raw.little_endian
                                                       );
            img.height := utl_raw.cast_to_binary_integer( dbms_lob.substr( p_img_blob, 2, ind + 7 )
                                                        , utl_raw.little_endian
                                                        );
            img.greyscale := false;
            ind := ind + 1 + 8;                   -- skip sentinel + img sizes
            flags := dbms_lob.substr( p_img_blob, 1, ind );
            if utl_raw.bit_and( flags, hextoraw( '80' ) ) = hextoraw( '80' )
            then
              t_len := 3 * power( 2, raw2num( utl_raw.bit_and( flags, hextoraw( '07' ) ) ) + 1 );
              img.color_tab := dbms_lob.substr( p_img_blob, t_len, ind + 1 );          -- Local Color Table
            end if;
            ind := ind + 1;                                -- skip image Flags
            min_code_size := blob2num( p_img_blob, 1, ind );
            ind := ind + 1;                      -- skip LZW Minimum Code Size
            dbms_lob.createtemporary( img_blob, true );
            loop
              t_len := blob2num( p_img_blob, 1, ind ); -- Block Size
              exit when t_len = 0;
              dbms_lob.append( img_blob, dbms_lob.substr( p_img_blob, t_len, ind + 1 ) ); -- Data Sub-block
              ind := ind + 1 + t_len;      -- skip Block Size + Data Sub-block
            end loop;
            ind := ind + 1;                            -- skip last Block Size
            img.pixels := lzw_decompress( img_blob, min_code_size + 1 );
--
            if utl_raw.bit_and( flags, hextoraw( '40' ) ) = hextoraw( '40' )
            then                                        --  interlaced
              declare
                pass pls_integer;
                pass_ind tp_pls_tab;
                l_mod number;
              begin
                dbms_lob.createtemporary( img_blob, true );
                pass_ind( 1 ) := 1;
                pass_ind( 2 ) := trunc( ( img.height - 1 ) / 8 ) + 1;
                pass_ind( 3 ) := pass_ind( 2 ) + trunc( ( img.height + 3 ) / 8 );
                pass_ind( 4 ) := pass_ind( 3 ) + trunc( ( img.height + 1 ) / 4 );
                pass_ind( 2 ) := pass_ind( 2 ) * img.width + 1;
                pass_ind( 3 ) := pass_ind( 3 ) * img.width + 1;
                pass_ind( 4 ) := pass_ind( 4 ) * img.width + 1;
                for i in 0 .. img.height - 1
                loop
                  l_mod := mod( i, 8 );
                  pass := case l_mod
                            when 0 then 1
                            when 4 then 2
                            when 2 then 3
                            when 6 then 3
                            else 4
                          end;
                  dbms_lob.append( img_blob, dbms_lob.substr( img.pixels, img.width, pass_ind( pass ) ) );
                  pass_ind( pass ) := pass_ind( pass ) + img.width;
                end loop;
                img.pixels := img_blob;
              end;
            end if;
--
            dbms_lob.freetemporary( img_blob );
          end;
        else
          exit;
      end case;
    end loop;
--
    img.type := 'gif';
    return img;
  end;
--
  function parse_img
    ( p_blob in blob
    , p_adler32 in varchar2 := null
    , p_type in varchar2 := null
    )
  return tp_img
  is
    t_img tp_img;
  begin
    t_img.type := p_type;
    if t_img.type is null
    then
      if rawtohex( dbms_lob.substr( p_blob, 8, 1 ) ) = '89504E470D0A1A0A'
      then
        t_img.type := 'png';
      elsif dbms_lob.substr( p_blob , 3, 1 ) = utl_raw.cast_to_raw( 'GIF' )
      then
        t_img.type := 'gif';
      else
        t_img.type := 'jpg';
      end if;
    end if;
--
    t_img := case lower( t_img.type )
               when 'gif' then parse_gif( p_blob )
               when 'png' then parse_png( p_blob )
               when 'jpg' then parse_jpg( p_blob )
               else null
             end;
--
    if t_img.type is not null
    then
      t_img.adler32 := coalesce( p_adler32, adler32( p_blob ) );
    end if;
    return t_img;
  end;
--
  procedure put_image
    ( p_img blob
    , p_x number
    , p_y number
    , p_width number := null
    , p_height number := null
    , p_align varchar2 := 'center'
    , p_valign varchar2 := 'top'
  )
  is
    t_x number;
    t_y number;
    t_img tp_img;
    t_ind pls_integer;
    t_adler32 varchar2(8);
  begin
    if p_img is null
    then
      return;
    end if;
    t_adler32 := adler32( p_img );
    t_ind := g_images.first;
    while t_ind is not null
    loop
      exit when g_images( t_ind ).adler32 = t_adler32;
      t_ind := g_images.next( t_ind );
    end loop;
--
    if t_ind is null
    then
      t_img := parse_img( p_img, t_adler32 );
      if t_img.adler32 is null
      then
        return;
      end if;
      t_ind := g_images.count( ) + 1;
      g_images( t_ind ) := t_img;
    end if;
--
    t_x := case substr( upper( p_align ), 1, 1 )
             when 'L' then p_x -- left
             when 'S' then p_x -- start
             when 'R' then p_x + nvl( p_width, 0 ) - g_images( t_ind ).width -- right
             when 'E' then p_x + nvl( p_width, 0 ) - g_images( t_ind ).width -- end
             else ( p_x + nvl( p_width, 0 ) - g_images( t_ind ).width ) / 2       -- center
           end;
    t_y := case substr( upper( p_valign ), 1, 1 )
             when 'C' then ( p_y - nvl( p_height, 0 ) + g_images( t_ind ).height ) / 2  -- center
             when 'B' then p_y - nvl( p_height, 0 ) + g_images( t_ind ).height -- bottom
             else p_y                                          -- top
           end;
--
    txt2page( 'q ' || to_char_round( least( nvl( p_width, g_images( t_ind ).width ), g_images( t_ind ).width ) )
            || ' 0 0 ' || to_char_round( least( nvl( p_height, g_images( t_ind ).height ), g_images( t_ind ).height ) )
            || ' ' || to_char_round( t_x ) || ' ' || to_char_round( t_y )
            || ' cm /I' || to_char( t_ind ) || ' Do Q'
            );
  end;
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
  )
  is
    t_blob blob;
  begin
    t_blob := file2blob( p_dir
                       , p_file_name
                       );
    put_image( t_blob
             , p_x
             , p_y
             , p_width
             , p_height
             , p_align
             , p_valign
             );
    dbms_lob.freetemporary( t_blob );
  end;
--
  procedure put_image
    ( p_url varchar2
    , p_x number
    , p_y number
    , p_width number := null
    , p_height number := null
    , p_align varchar2 := 'center'
    , p_valign varchar2 := 'top'
    )
  is
    t_blob blob;
  begin
    t_blob := httpuritype( p_url ).getblob( );
    put_image( t_blob
             , p_x
             , p_y
             , p_width
             , p_height
             , p_align
             , p_valign
             );
    dbms_lob.freetemporary( t_blob );
  end;
--
  procedure set_page_proc( p_src clob )
  is
  begin
    g_page_prcs( g_page_prcs.count ) := p_src;
  end;
--
  procedure cursor2table
    ( p_c integer
    , p_widths tp_col_widths := null
    , p_headers tp_headers := null
    )
  is
    t_col_cnt integer;
$IF DBMS_DB_VERSION.VER_LE_10 $THEN
    t_desc_tab dbms_sql.desc_tab2;
$ELSE
    t_desc_tab dbms_sql.desc_tab3;
$END
    d_tab dbms_sql.date_table;
    n_tab dbms_sql.number_table;
    v_tab dbms_sql.varchar2_table;
    t_bulk_size pls_integer := 200;
    t_r integer;
    t_cur_row pls_integer;
    type tp_integer_tab is table of integer;
    t_chars tp_integer_tab := tp_integer_tab( 1, 8, 9, 96, 112 );
    t_dates tp_integer_tab := tp_integer_tab( 12, 178, 179, 180, 181 , 231 );
    t_numerics tp_integer_tab := tp_integer_tab( 2, 100, 101 );
    t_widths tp_col_widths;
    t_tmp number;
    t_x number;
    t_y number;
    t_start_x number;
    t_lineheight number;
    t_padding number := 2;
    t_num_format varchar2(100) := 'tm9';
    t_date_format varchar2(100) := 'dd.mm.yyyy';
    t_txt varchar2(32767);
    c_rf number := 0.2; -- raise factor of text above cell bottom 
--
    procedure show_header
    is
    begin
      if p_headers is not null and p_headers.count > 0
      then
        t_x := t_start_x;
        for c in 1 .. t_col_cnt
        loop
          rect( t_x, t_y, t_widths( c ), t_lineheight );
          if c <= p_headers.count
          then
            put_txt( t_x + t_padding, t_y + c_rf * t_lineheight, p_headers( c ) );
          end if; 
          t_x := t_x + t_widths( c ); 
        end loop;
        t_y := t_y - t_lineheight;
      end if;
    end;
--
  begin
$IF DBMS_DB_VERSION.VER_LE_10 $THEN
    dbms_sql.describe_columns2( p_c, t_col_cnt, t_desc_tab );
$ELSE
    dbms_sql.describe_columns3( p_c, t_col_cnt, t_desc_tab );
$END
    if p_widths is null or p_widths.count < t_col_cnt
    then
      t_tmp := get( c_get_page_width ) - get( c_get_margin_left ) - get( c_get_margin_right );
      t_widths := tp_col_widths();
      t_widths.extend( t_col_cnt );  
      for c in 1 .. t_col_cnt
      loop
        t_widths( c ) := round( t_tmp / t_col_cnt, 1 ); 
      end loop;
    else
      t_widths := p_widths;
    end if;
--
    if get( c_get_current_font ) is null
    then 
      set_font( 'helvetica', 12 );
    end if;
--
    for c in 1 .. t_col_cnt
    loop
      case
        when t_desc_tab( c ).col_type member of t_numerics
        then
          dbms_sql.define_array( p_c, c, n_tab, t_bulk_size, 1 );
        when t_desc_tab( c ).col_type member of t_dates
        then
          dbms_sql.define_array( p_c, c, d_tab, t_bulk_size, 1 );
        when t_desc_tab( c ).col_type member of t_chars
        then
          dbms_sql.define_array( p_c, c, v_tab, t_bulk_size, 1 );
        else
          null;
      end case;
    end loop;
--
    t_start_x := get( c_get_margin_left );
    t_lineheight := get( c_get_fontsize ) * 1.2;
    t_y := coalesce( get( c_get_y ) - t_lineheight, get( c_get_page_height ) - get( c_get_margin_top ) ) - t_lineheight; 
--
    show_header;
--
    loop
      t_r := dbms_sql.fetch_rows( p_c );
      for i in 0 .. t_r - 1
      loop
        if t_y < get( c_get_margin_bottom )
        then
          new_page;
          t_y := get( c_get_page_height ) - get( c_get_margin_top ) - t_lineheight; 
          show_header;
        end if;
        t_x := t_start_x;
        for c in 1 .. t_col_cnt
        loop
          case
            when t_desc_tab( c ).col_type member of t_numerics
            then
              n_tab.delete;
              dbms_sql.column_value( p_c, c, n_tab );
              rect( t_x, t_y, t_widths( c ), t_lineheight );
              t_txt := to_char( n_tab( i + n_tab.first() ), t_num_format );
              if t_txt is not null
              then
                put_txt( t_x + t_widths( c ) - t_padding - str_len( t_txt ), t_y + c_rf * t_lineheight, t_txt );
              end if; 
              t_x := t_x + t_widths( c ); 
            when t_desc_tab( c ).col_type member of t_dates
            then
              d_tab.delete;
              dbms_sql.column_value( p_c, c, d_tab );
              rect( t_x, t_y, t_widths( c ), t_lineheight );
              t_txt := to_char( d_tab( i + d_tab.first() ), t_date_format );
              if t_txt is not null
              then
                put_txt( t_x + t_padding, t_y + c_rf * t_lineheight, t_txt );
              end if; 
              t_x := t_x + t_widths( c ); 
            when t_desc_tab( c ).col_type member of t_chars
            then
              v_tab.delete;
              dbms_sql.column_value( p_c, c, v_tab );
              rect( t_x, t_y, t_widths( c ), t_lineheight );
              t_txt := v_tab( i + v_tab.first() );
              if t_txt is not null
              then
                put_txt( t_x + t_padding, t_y + c_rf * t_lineheight, t_txt );
              end if; 
              t_x := t_x + t_widths( c ); 
            else
              null;
          end case;
        end loop;
        t_y := t_y - t_lineheight;
      end loop;
      exit when t_r != t_bulk_size;
    end loop;      
    g_y := t_y;
  end;
--
  procedure query2table
    ( p_query varchar2
    , p_widths tp_col_widths := null
    , p_headers tp_headers := null
    )
  is
    t_cx integer;
    t_dummy integer;
  begin
    t_cx := dbms_sql.open_cursor;
    dbms_sql.parse( t_cx, p_query, dbms_sql.native );
    t_dummy := dbms_sql.execute( t_cx );
    cursor2table( t_cx, p_widths, p_headers ); 
    dbms_sql.close_cursor( t_cx );
  end;
$IF not DBMS_DB_VERSION.VER_LE_10 $THEN
--
  procedure refcursor2table
    ( p_rc sys_refcursor
    , p_widths tp_col_widths := null
    , p_headers tp_headers := null
    )
  is
    t_cx integer;
    t_rc sys_refcursor;
  begin
    t_rc := p_rc;
    t_cx := dbms_sql.to_cursor_number( t_rc );
    cursor2table( t_cx, p_widths, p_headers ); 
    dbms_sql.close_cursor( t_cx );
  end;
$END

end as_pdf3;
/

