CREATE OR REPLACE package body pdf_builder_pkg
as
--
  type tp_objects_tab is table of number(10) index by pls_integer;
  type tp_pages_tab is table of blob index by pls_integer;
  type tp_char_width_tab is table of pls_integer index by pls_integer;
  type tp_font is record
    ( char_width_tab tp_char_width_tab
    , standard boolean
    , family varchar2(100)
    , style varchar2(2) -- N Normal
                        -- I Italic
                        -- B Bold
                        -- BI Bold Italic
    , subtype varchar2(15) := 'Type1'
    , name varchar2(100)
    , encoding varchar2(100) := 'WINDOWS-1252'
    );
  type tp_font_tab is table of tp_font index by pls_integer;
  type tp_pls_tab is table of pls_integer index by pls_integer;
  type tp_img is record
    ( adler32 varchar2(8)
    , width  pls_integer
    , height pls_integer
    , color_res pls_integer
    , color_tab raw(768)
    , greyscale boolean
    , pixels blob
    , type varchar2(5)
    , nr_colors pls_integer
    );
  type tp_img_tab is table of tp_img index by pls_integer;
--
-- pacakges globals
  pdf_doc blob; -- the blob containing the build PDF document
  objects_tab tp_objects_tab;
  pages_tab tp_pages_tab;
  settings tp_settings;
  fonts tp_font_tab;
  used_fonts tp_pls_tab;
  images tp_img_tab;
  t_ncharset varchar2(1000);
  t_lan_ter  varchar2(1000);
--
  procedure init_core_fonts
  is
    function init_standard_withs( p_compressed_tab in varchar2 )
    return tp_char_width_tab
    is
      t_rv tp_char_width_tab;
      t_tmp raw(32767);
    begin
      t_tmp := utl_compress.lz_uncompress( utl_encode.base64_decode( utl_raw.cast_to_raw( p_compressed_tab ) ) );
      for i in 0 .. 255
      loop
        t_rv( i ) := utl_raw.cast_to_binary_integer( utl_raw.substr( t_tmp, i * 4 + 1, 4 ) );
      end loop;
      return t_rv;
    end;
  begin
    fonts( 1 ).family := 'helvetica';
    fonts( 1 ).style := 'N'; -- Normal
    fonts( 1 ).name := 'Helvetica';
    fonts( 1 ).standard := true;
    fonts( 1 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC81Tuw3CMBC94FQMgMQOLAGVGzNCGtc0dAxAT+8lsgE7RKJFomOA' ||
        'SLT4frHjBEFJ8XSX87372C8A1Qr+Ax5gsWGYU7QBAK4x7gTnGLOS6xJPOd8w5NsM' ||
        '2OvFvQidAP04j1nyN3F7iSNny3E6DylPeeqbNqvti31vMpfLZuzH86oPdwaeo6X+' ||
        '5X6Oz5VHtTqJKfYRNVu6y0ZyG66rdcxzXJe+Q/KJ59kql+bTt5K6lKucXvxWeHKf' ||
        '+p6Tfersfh7RHuXMZjHsdUkxBeWtM60gDjLTLoHeKsyDdu6m8VK3qhnUQAmca9BG' ||
        'Dq3nP+sV/4FcD6WOf9K/ne+hdav+DTuNLeYABAAA'
      );
--
    fonts( 2 ).family := 'helvetica';
    fonts( 2 ).style := 'I'; -- Italic
    fonts( 2 ).name := 'Helvetica-Oblique';
    fonts( 2 ).standard := true;
    fonts( 2 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC81Tuw3CMBC94FQMgMQOLAGVGzNCGtc0dAxAT+8lsgE7RKJFomOA' || 
        'SLT4frHjBEFJ8XSX87372C8A1Qr+Ax5gsWGYU7QBAK4x7gTnGLOS6xJPOd8w5NsM' || 
        '2OvFvQidAP04j1nyN3F7iSNny3E6DylPeeqbNqvti31vMpfLZuzH86oPdwaeo6X+' || 
        '5X6Oz5VHtTqJKfYRNVu6y0ZyG66rdcxzXJe+Q/KJ59kql+bTt5K6lKucXvxWeHKf' || 
        '+p6Tfersfh7RHuXMZjHsdUkxBeWtM60gDjLTLoHeKsyDdu6m8VK3qhnUQAmca9BG' || 
        'Dq3nP+sV/4FcD6WOf9K/ne+hdav+DTuNLeYABAAA'
      );
--
    fonts( 3 ).family := 'helvetica';
    fonts( 3 ).style := 'B'; -- Bold
    fonts( 3 ).name := 'Helvetica-Bold';
    fonts( 3 ).standard := true;
    fonts( 3 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC8VSsRHCMAx0SJcBcgyRJaBKkxXSqKahYwB6+iyRTbhLSUdHRZUB' || 
        'sOWXLF8SKCn+ZL/0kizZuaJ2/0fn8XBu10SUF28n59wbvoCr51oTD61ofkHyhBwK' || 
        '8rXusVaGAb4q3rXOBP4Qz+wfUpzo5FyO4MBr39IH+uLclFvmCTrz1mB5PpSD52N1' || 
        'DfqS988xptibWfbw9Sa/jytf+dz4PqQz6wi63uxxBpCXY7uUj88jNDNy1mYGdl97' || 
        '856nt2f4WsOFed4SpzumNCvlT+jpmKC7WgH3PJn9DaZfA42vlgh96d+wkHy0/V95' || 
        'xyv8oj59QbvBN2I/iAuqEAAEAAA='
      );
--
    fonts( 4 ).family := 'helvetica';
    fonts( 4 ).style := 'BI'; -- Bold Italic
    fonts( 4 ).name := 'Helvetica-BoldOblique';
    fonts( 4 ).standard := true;
    fonts( 4 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC8VSsRHCMAx0SJcBcgyRJaBKkxXSqKahYwB6+iyRTbhLSUdHRZUB' || 
        'sOWXLF8SKCn+ZL/0kizZuaJ2/0fn8XBu10SUF28n59wbvoCr51oTD61ofkHyhBwK' || 
        '8rXusVaGAb4q3rXOBP4Qz+wfUpzo5FyO4MBr39IH+uLclFvmCTrz1mB5PpSD52N1' || 
        'DfqS988xptibWfbw9Sa/jytf+dz4PqQz6wi63uxxBpCXY7uUj88jNDNy1mYGdl97' || 
        '856nt2f4WsOFed4SpzumNCvlT+jpmKC7WgH3PJn9DaZfA42vlgh96d+wkHy0/V95' || 
        'xyv8oj59QbvBN2I/iAuqEAAEAAA='
      );
--
    fonts( 5 ).family := 'times';
    fonts( 5 ).style := 'N'; -- Normal
    fonts( 5 ).name := 'Times-Roman';
    fonts( 5 ).standard := true;
    fonts( 5 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC8WSKxLCQAyG+3Bopo4bVHbwHGCvUNNT9AB4JEwvgUBimUF3wCNR' || 
        'qAoGRZL9twlQikR8kzTvZBtF0SP6O7Ej1kTnSRfEhHw7+Jy3J4XGi8w05yeZh2sE' || 
        '4j312ZDeEg1gvSJy6C36L9WX1urr4xrolfrSrYmrUCeDPGMu5+cQ3Ur3OXvQ+TYf' || 
        '+2FGexOZvTM1L3S3o5fJjGQJX2n68U2ur3X5m3cTvfbxsk9pcsMee60rdTjnhNkc' || 
        'Zip9HOv9+7/tI3Oif3InOdV/oLdx3gq2HIRaB1Ob7XPk35QwwxDyxg3e09Dv6nSf' || 
        'rxQjvty8ywDce9CXvdF9R+4y4o+7J1P/I9sABAAA'
      );
--
    fonts( 6 ).family := 'times';
    fonts( 6 ).style := 'I'; -- Italic
    fonts( 6 ).name := 'Times-Italic';
    fonts( 6 ).standard := true;
    fonts( 6 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC8WSPQ6CQBCFF+i01NB5g63tPcBegYZTeAB6SxNLjLUH4BTEeAYr' || 
        'Kwpj5ezsW2YgoKXFl2Hnb9+wY4x5m7+TOOJMdIFsRywodkfMBX9aSz7bXGp+gj6+' || 
        'R4TvOtJ3CU5Eq85tgGsbxG3QN8iFZY1WzpxXwkckFTR7e1G6osZGWT1bDuBnTeP5' || 
        'KtW/E71c0yB2IFbBphuyBXIL9Y/9fPvhf8se6vsa8nmeQtU6NSf6ch9fc8P9DpqK' || 
        'cPa5/I7VxDwruTN9kV3LDvQ+h1m8z4I4x9LIbnn/Fv6nwOdyGq+d33jk7/cxztyq' || 
        'XRhTz/it7Mscg7fT5CO+9ahnYk20Hww5IrwABAAA'
      );
--
    fonts( 7 ).family := 'times';
    fonts( 7 ).style := 'B'; -- Bold
    fonts( 7 ).name := 'Times-Bold';
    fonts( 7 ).standard := true;
    fonts( 7 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC8VSuw3CQAy9XBqUAVKxAZkgHQUNEiukySxpqOjTMQEDZIrUDICE' || 
        'RHUVVfy9c0IQJcWTfbafv+ece7u/Izs553cgAyN/APagl+wjgN3XKZ5kmTg/IXkw' || 
        'h4JqXUEfAb1I1VvwFYysk9iCffmN4+gtccSr5nlwDpuTepCZ/MH0FZibDUnO7MoR' || 
        'HXdDuvgjpzNxgevG+dF/hr3dWfoNyEZ8Taqn+7d7ozmqpGM8zdMYruFrXopVjvY2' || 
        'in9gXe+5vBf1KfX9E6TOVBsb8i5iqwQyv9+a3Gg/Cv+VoDtaQ7xdPwfNYRDji09g' || 
        'X/FvLNGmO62B9jSsoFwgfM+jf1z/SPwrkTMBOkCTBQAEAAA='
      );
--
    fonts( 8 ).family := 'times';
    fonts( 8 ).style := 'BI'; -- Bold Italic
    fonts( 8 ).name := 'Times-BoldItalic';
    fonts( 8 ).standard := true;
    fonts( 8 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC8WSuw2DMBCGHegYwEuECajIAGwQ0TBFBnCfPktkAKagzgCRIqWi' || 
        'oso9fr+Qo5RB+nT2ve+wMWYzf+fgjKmOJFelPhENnS0xANJXHfwHSBtjfoI8nMMj' || 
        'tXo63xKW/Cx9ONRn3US6C/wWvYeYNr+LH2IY6cHGPkJfvsc5kX7mFjF+Vqs9iT6d' || 
        'zwEL26y1Qz62nWlvD5VSf4R9zPuon/ne+C45+XxXf5lnTGLTOZCXPx8v9Qfdjdid' || 
        '5vD/f/+/pE/Ur14kG+xjTHRc84pZWsC2Hjk2+Hgbx78j4Z8W4DlL+rBnEN5Bie6L' || 
        'fsL+1u/InuYCdsdaeAs+RxftKfGdfQDlDF/kAAQAAA=='
      );
--
    fonts( 9 ).family := 'courier';
    fonts( 9 ).style := 'N'; -- Normal
    fonts( 9 ).name := 'Courier';
    fonts( 9 ).standard := true;
    for i in 0 .. 255
    loop
      fonts( 9 ).char_width_tab( i ) := 600;
    end loop;
--
    fonts( 10 ).family := 'courier';
    fonts( 10 ).style := 'I'; -- Italic
    fonts( 10 ).name := 'Courier-Oblique';
    fonts( 10 ).standard := true;
    fonts( 10 ).char_width_tab := fonts( 9 ).char_width_tab;
--
    fonts( 11 ).family := 'courier';
    fonts( 11 ).style := 'BI'; -- Bold
    fonts( 11 ).name := 'Courier-Bold';
    fonts( 11 ).standard := true;
    fonts( 11 ).char_width_tab := fonts( 9 ).char_width_tab;
--
    fonts( 12 ).family := 'courier';
    fonts( 12 ).style := 'BI'; -- Bold Italic
    fonts( 12 ).name := 'Courier-BoldOblique';
    fonts( 12 ).standard := true;
    fonts( 12 ).char_width_tab := fonts( 9 ).char_width_tab;
--
    fonts( 13 ).family := 'symbol';
    fonts( 13 ).style := 'N'; -- Normal
    fonts( 13 ).name := 'Symbol';
    fonts( 13 ).standard := true;
    fonts( 13 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC82SIU8DQRCFZ28xIE+cqcbha4tENKk/gQCJJ6AweIK9H1CHqKnp' || 
        'D2gTFBaDIcFwCQkJSTG83fem7SU0qYNLvry5nZ25t7NnZkv7c8LQrFhAP6GHZvEY' || 
        'HOB9ylxGubTfNVRc34mKpFonzBQ/gUZ6Ds7AN6i5lv1dKv8Ab1eKQYSV4hUcgZFq' || 
        'J/Sec7fQHtdTn3iqfvdrb7m3e2pZW+xDG3oIJ/Li3gfMr949rlU74DyT1/AuTX1f' || 
        'YGhOzTP8B0/RggsEX/I03vgXPrrslZjfM8/pGu40t2ZjHgud97F7337mXP/GO4h9' || 
        '3WmPPaOJ/jrOs9yC52MlrtUzfWupfTX51X/L+13Vl/J/s4W2S3pSfSh5DmeXerMf' || 
        '+LXhWQAEAAA='
      );
--
    fonts( 14 ).family := 'zapfdingbats';
    fonts( 14 ).style := 'N'; -- Normal
    fonts( 14 ).name := 'ZapfDingbats';
    fonts( 14 ).standard := true;
    fonts( 14 ).char_width_tab := init_standard_withs
      ( 'H4sIAAAAAAAAC83ROy9EQRjG8TkzjdJl163SSHR0EpdsVkSi2UahFhUljUKUIgoq' || 
        'CrvJCtFQyG6EbSSERGxhC0ofQAQFxbIi8T/7PoUPIOEkvzxzzsycdy7O/fUTtToX' || 
        'bnCuvHPOV8gk4r423ovkGQ5od5OTWMeesmBz/RuZIWv4wCAY4z/xjipeqflC9qAD' || 
        'aRwxrxkJievSFzrRh36tZ1zttL6nkGX+A27xrLnttE/IBji9x7UvcIl9nPJ9AL36' || 
        'd1L9hyihoDW10L62cwhNyhntryZVExYl3kMj+zym+CrJv6M8VozPmfr5L8uwJORL' || 
        'tox7NFHG/Obj79FlwhqZ1X292xn6CbAXP/fjjv6rJYyBtUdl1vxEO6fcRB7bMmJ3' || 
        'GYZsTN0GdrDL/Ao5j1GZNr5kwqydX5z1syoiYEq5gCtlSrXi+mVbi3PfVAuhoQAE' || 
        'AAA='
      );
--
  end;
--
  function pdf_string( p_txt in blob )
  return blob
  is
    t_rv blob;
    t_ind integer;
    type tp_tab_raw is table of raw(1);
    tab_raw tp_tab_raw := tp_tab_raw( utl_raw.cast_to_raw( '\' )
                                    , utl_raw.cast_to_raw( '(' )
                                    , utl_raw.cast_to_raw( ')' )
                                    );
  begin
    t_rv := p_txt;
    for i in tab_raw.first .. tab_raw.last
    loop 
      t_ind := -1;
      loop
        t_ind := dbms_lob.instr( t_rv, tab_raw( i ), t_ind + 2 );
        exit when t_ind <= 0;
        dbms_lob.copy( t_rv, t_rv, dbms_lob.lobmaxsize, t_ind + 1, t_ind );
        dbms_lob.copy( t_rv, tab_raw( 1 ), 1, t_ind, 1 );
      end loop;
    end loop;
    return t_rv;
  end;
--
  function raw2num( p_value in raw )
  return number
  is
  begin -- note: FFFFFFFF => -1
    return utl_raw.cast_to_binary_integer( p_value );
  end;
--
  function to_char_round( p_value in number, p_precision in pls_integer := 2 )
  return varchar2
  is
  begin
    return rtrim( rtrim( to_char( p_value, rpad( '9999999990D'
                                               , 11 + p_precision
                                               , '0'
                                               )
                                , 'NLS_NUMERIC_CHARACTERS = ''.,''' ), '0' )
                , '.'
                );
  end;
--
  function file2blob( p_dir in varchar2, p_file_name in varchar2 )
  return blob
  is
    file_lob bfile;
    file_blob blob;
  begin
    file_lob := bfilename( p_dir, p_file_name );
    dbms_lob.open( file_lob, dbms_lob.file_readonly );
    dbms_lob.createtemporary( file_blob, true );
    dbms_lob.loadfromfile( file_blob, file_lob, dbms_lob.lobmaxsize );
    dbms_lob.close( file_lob );
    return file_blob;
  exception
    when others then
      if dbms_lob.isopen( file_lob ) = 1
      then
        dbms_lob.close( file_lob );
      end if;
      if dbms_lob.istemporary( file_blob ) = 1
      then
        dbms_lob.freetemporary( file_blob );
      end if;
      raise;
  end;
--
  procedure raw2pdfDoc( p_txt in blob )
  is
  begin
    dbms_lob.append( pdf_doc, p_txt );
  end;
--
  procedure add2pdfDoc( p_txt in varchar2 )
  is
  begin
    raw2pdfDoc( utl_raw.concat( utl_raw.cast_to_raw( p_txt ), hextoraw( '0D0A' ) ) );
  end;
--
  function add_object2pdfDoc( p_txt in varchar2 := null )
  return number
  is
    t_self number(10);
  begin
    t_self := objects_tab.count();
    objects_tab( t_self ) := dbms_lob.getlength( pdf_doc );
    add2pdfDoc( t_self || ' 0 obj' );
    if p_txt is not null
    then
      add2pdfDoc( '<<' || p_txt || '>>' || chr(13) || chr(10) || 'endobj' );
    end if;
    return t_self;
  end;
--
  procedure add_object2pdfDoc( p_txt in varchar2 := null )
  is
    t_self number(10);
  begin
    t_self := add_object2pdfDoc( p_txt );
  end;
--
  function adler32( p_src in blob )
  return varchar2
  is
    s1 pls_integer := 1;
    s2 pls_integer := 0;
  begin
    for i in 1 .. dbms_lob.getlength( p_src )
    loop
      s1 := mod( s1 + utl_raw.cast_to_binary_integer( dbms_lob.substr( p_src, 1, i ) ), 65521 );
      s2 := mod( s2 + s1, 65521);
    end loop;
    return to_char( s2, 'fm0XXX' ) || to_char( s1, 'fm0XXX' );
  end;
--
  function Flate_encode( p_val in blob )
  return blob
  is
    t_cpr blob;
    t_blob blob;
--
  begin
    t_cpr := utl_compress.lz_compress( p_val );
    t_blob := hextoraw( '789C' );
    dbms_lob.copy( t_blob, t_cpr, dbms_lob.getlength( t_cpr ) - 10 - 8, 3, 11 );
    dbms_lob.append( t_blob, hextoraw( adler32( p_val ) ) );
    dbms_lob.freetemporary( t_cpr );
    return t_blob;
  end;
--
  procedure put_stream( p_stream in blob, p_compress in boolean := true, p_extra in varchar2 := '' )
  is
    t_blob blob;
  begin
    if p_compress
    then
      t_blob := Flate_encode( p_stream );
      put_stream( t_blob, false, '/Filter /FlateDecode ' || p_extra );
      dbms_lob.freetemporary( t_blob );
    else
      add2pdfDoc( '/Length ' || dbms_lob.getlength( p_stream ) || p_extra || ' >>' );
      add2pdfDoc( 'stream' );
      raw2pdfDoc( p_stream );
      add2pdfDoc( 'endstream' );
    end if;
  end;
--
  function add_stream( p_stream in blob, p_extra in varchar2 := '', p_compress in boolean := true )
  return number
  is
    t_self number(10);
  begin
    t_self := add_object2pdfDoc;
    add2pdfDoc( '<<' );
    put_stream( p_stream, p_compress, p_extra );
    add2pdfDoc( 'endobj' );
    return t_self;
  end;
--
  function add_info
  return number
  is
    t_banner varchar2(1000);
  begin
    begin
      select 'running on ' || replace( replace( replace( substr( banner, 1, 950), '\', '\\' ), '(', '\(' ), ')', '\)' )
      into t_banner
      from v$version
      where instr( upper( banner ), 'DATABASE' ) > 0;
--
      t_banner := '/Producer (' || t_banner || ')';
    exception
      when others
      then
        null;
    end;
--
    return add_object2pdfDoc
             (  '/CreationDate (D:' || to_char( sysdate, 'YYYYMMDDhh24miss' ) || ')'
             || '/Creator (AS-PDF mini 0.2.0 by Anton Scheffer)'
             || t_banner
             );
  end;
--
  function add_font( p_index in pls_integer )
  return number
  is
  begin
    return add_object2pdfDoc
             (  '/Type/Font'
             || '/Subtype/' || fonts( p_index ).subtype
             || '/BaseFont/' || fonts( p_index ).name
             || '/Encoding/WinAnsiEncoding' -- code page 1252
             );
  end;
--
  procedure add_image( p_img in tp_img )
  is
    t_self   number(10);
    t_pallet number(10);
  begin
    if p_img.color_tab is not null
    then
      t_pallet := add_stream( p_img.color_tab );
    else
      t_pallet := add_object2pdfDoc; -- add an empty object
      add2pdfDoc( 'endobj' );
    end if;
    t_self := add_object2pdfDoc;
    add2pdfDoc( '<</Type /XObject /Subtype /Image' );
    add2pdfDoc( ' /Width ' || to_char( p_img.width ) || ' /Height ' || to_char( p_img.height ) );
    add2pdfDoc( '/BitsPerComponent ' || to_char( p_img.color_res ) );
    if p_img.color_tab is null
    then
      if p_img.greyscale
      then
        add2pdfDoc( '/ColorSpace /DeviceGray' );
      else
        add2pdfDoc( '/ColorSpace /DeviceRGB' );
      end if;
    else
      add2pdfDoc( '/ColorSpace [/Indexed /DeviceRGB ' || to_char( utl_raw.length( p_img.color_tab ) / 3 - 1 ) || ' ' || to_char( t_pallet ) || ' 0 R]' );
    end if;
    if p_img.type = 'jpg'
    then
      put_stream( p_img.pixels, false, '/Filter /DCTDecode' );
    elsif p_img.type = 'png'
    then
      put_stream( p_img.pixels, false, ' /Filter /FlateDecode /DecodeParms <</Predictor 15 /Colors ' || p_img.nr_colors || '/BitsPerComponent ' || p_img.color_res || ' /Columns ' || p_img.width || ' >>' );
    else
      put_stream( p_img.pixels );
    end if;
    add2pdfDoc( 'endobj' );
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
    t_ind := used_fonts.first;
    while t_ind is not null
    loop
      t_fonts( t_ind ) := add_font( t_ind );
      t_ind := used_fonts.next( t_ind );
    end loop;
--
    t_self := add_object2pdfDoc;
    add2pdfDoc( '<</ProcSet [/PDF /Text]' );
    add2pdfDoc( '/Font' );
    add2pdfDoc( '  <<' );
    t_ind := used_fonts.first;
    while t_ind is not null
    loop
      add2pdfDoc( '    /F' || to_char( t_ind ) || ' ' || to_char( t_fonts( t_ind ) ) || ' 0 R' );
      t_ind := used_fonts.next( t_ind );
    end loop;
    add2pdfDoc( '  >>' );
    if images.count() > 0
    then
      add2pdfDoc( '/XObject <<' );
      for i in images.first .. images.last
      loop
        add2pdfDoc( '    /I' || to_char( i ) || ' ' || to_char( t_self + 2 * i ) || ' 0 R' );
      end loop;
      add2pdfDoc( '>>' );
    end if;
    add2pdfDoc( '>>' );
    add2pdfDoc( 'endobj' );
--
    if images.count() > 0
    then
      for i in images.first .. images.last
      loop
        add_image( images( i ) );
      end loop;
    end if;
--
    return t_self;
  end;
--
  procedure add_page
    ( p_page_nr in pls_integer
    , p_parent in number
    , p_resources in number
    )
  is
    t_content number(10);
  begin
    t_content := add_stream( pages_tab( p_page_nr ) );
    add_object2pdfDoc;
    add2pdfDoc( '<< /Type /Page' );
    add2pdfDoc( '/Parent ' || to_char( p_parent ) || ' 0 R' );
    add2pdfDoc( '/Contents ' || to_char( t_content ) || ' 0 R' );
    add2pdfDoc( '/Resources ' || to_char( p_resources ) || ' 0 R' );
    add2pdfDoc( '>>' );
    add2pdfDoc( 'endobj' );
  end;
--
  function add_pages
  return number
  is
    t_self number(10);
    t_resources number(10);
  begin
    t_resources := add_resources;
    t_self := add_object2pdfDoc;
    add2pdfDoc( '<</Type/Pages/Kids [' );
    for i in pages_tab.first .. pages_tab.last
    loop
      add2pdfDoc( to_char( t_self + i * 2 + 2 ) || ' 0 R' );
    end loop;
    add2pdfDoc( ']' );
    add2pdfDoc( '/Count ' || pages_tab.count() );
    add2pdfDoc( '/MediaBox [0 0 ' || to_char_round( settings.page_width, 0 ) || ' ' || to_char_round( settings.page_height, 0 ) || ']' );
    add2pdfDoc( '>>' );
    add2pdfDoc( 'endobj' );
--
    for i in pages_tab.first .. pages_tab.last
    loop
      add_page( i, t_self, t_resources );
    end loop;
--
    return t_self;
  end;
--
  function add_catalogue
  return number
  is
  begin
    return add_object2pdfDoc
             (  '/Type/Catalog'
             || '/Pages ' || to_char( add_pages ) || ' 0 R'
             || '/OpenAction [0 /XYZ null null 1]'
             );
  end;
--
  procedure finish_pdf
  is
    t_xref number(10);
    t_info number(10);
    t_catalogue number(10);
  begin
    add2pdfDoc( '%PDF-1.3' );
    raw2pdfDoc( hextoraw( '25E2E3CFD30D0A' ) ); -- add a hex comment
    t_info := add_info;
    t_catalogue := add_catalogue;
    t_xref := dbms_lob.getlength( pdf_doc );
    add2pdfDoc( 'xref' );
    add2pdfDoc( '0 ' || to_char( objects_tab.count() ) );
    add2pdfDoc( '0000000000 65535 f ' );
    for i in 1 .. objects_tab.count() - 1
    loop
      add2pdfDoc( to_char( objects_tab( i ), 'fm0000000000' ) || ' 00000 n' );  -- this line should be exactly 20 bytes, including EOL
    end loop;
    add2pdfDoc( 'trailer' );
    add2pdfDoc( '<< /Root ' || to_char( t_catalogue ) || ' 0 R' );
    add2pdfDoc( '/Info ' || to_char( t_info ) || ' 0 R' );
    add2pdfDoc( '/Size ' || to_char( objects_tab.count()  ) );
    add2pdfDoc( '>>' );
    add2pdfDoc( 'startxref' );
    add2pdfDoc( to_char( t_xref ) );
    add2pdfDoc( '%%EOF' );
--
    objects_tab.delete;
    for i in pages_tab.first .. pages_tab.last
    loop
      dbms_lob.freetemporary( pages_tab( i ) );
    end loop;
    pages_tab.delete;
    fonts.delete;
    used_fonts.delete;
    if images.count() > 0
    then
      for i in images.first .. images.last
      loop
        if dbms_lob.istemporary( images( i ).pixels ) = 1
        then
          dbms_lob.freetemporary( images( i ).pixels );
        end if;
      end loop;
    end if;
    images.delete;
    settings := null;
  end;
--
  function get_settings
  return tp_settings
  is
  begin
    return settings;
  end;
--
  procedure new_page
  is
  begin
    pages_tab( pages_tab.count() ) := null;
    dbms_lob.createtemporary( pages_tab( pages_tab.count() - 1 ), true );
--
    settings.x := settings.margin_left;
    settings.y := settings.page_height - settings.margin_top - nvl( settings.current_fontsizePt, 12 );
    settings.page_nr := pages_tab.count();
--
    if settings.current_font is not null
    then
      add2page( 'BT /F' || settings.current_font || ' ' ||
                to_char_round( settings.current_fontsizePt ) || ' Tf ET'
              );
    end if;
  end;
--
  function parse_png( p_img_blob in blob )
  return tp_img
  is
    t_img tp_img;
    buf raw(32767);
    len integer;
    ind integer;
    color_type pls_integer;
  begin
    if rawtohex( dbms_lob.substr( p_img_blob, 8, 1 ) ) != '89504E470D0A1A0A'
    then -- not the right signature
      return null;
    end if;
    dbms_lob.createtemporary( t_img.pixels, true );
    ind := 9;
    loop
      len := raw2num( dbms_lob.substr( p_img_blob, 4, ind ) ); -- length
      exit when len is null or ind > dbms_lob.getlength( p_img_blob );
      case utl_raw.cast_to_varchar2( dbms_lob.substr( p_img_blob, 4, ind + 4 ) ) -- Chunk type
      when 'IHDR'
      then
        t_img.width := raw2num( dbms_lob.substr( p_img_blob, 4, ind + 8 ) );
        t_img.height := raw2num( dbms_lob.substr( p_img_blob, 4, ind + 12 ) );
        t_img.color_res := raw2num( dbms_lob.substr( p_img_blob, 1, ind + 16 ) );
        color_type := raw2num( dbms_lob.substr( p_img_blob, 1, ind + 17 ) );
        t_img.greyscale := color_type in ( 0, 4 );
        when 'PLTE'
        then
          t_img.color_tab := dbms_lob.substr( p_img_blob, len, ind + 8 );
        when 'IDAT'
        then
          dbms_lob.append( t_img.pixels, dbms_lob.substr( p_img_blob, len, ind + 8 ) );
        when 'IEND'
        then
          exit;
        else
          null;
      end case;
      ind := ind + 4 + 4 + len + 4; -- Length + Chunk type + Chunk data + CRC
    end loop;
--
    t_img.type := 'png';
    t_img.nr_colors := case color_type when 0 then 1 when 2 then 3 when 3 then 1 when 4 then 2 else 4 end;
--
    return t_img;
  end;
--
  function parse_jpg( p_img_blob in blob )
  return tp_img
  is
    buf raw(4);
    t_img tp_img;
    t_ind integer;
  begin
    if (  dbms_lob.substr( p_img_blob, 2, 1 ) != hextoraw( 'FFD8' )  -- SOI Start of Image
       or dbms_lob.substr( p_img_blob, 2, dbms_lob.getlength( p_img_blob ) - 1 )  != hextoraw( 'FFD9' )  -- EOI End of Image
       )
    then -- this is not a jpg I can handle
      return null;
    end if;
--
    t_img.pixels := p_img_blob;
    t_img.type := 'jpg';
    if dbms_lob.substr( t_img.pixels, 2, 3 ) in ( hextoraw( 'FFE0' ) -- a APP0 jpg
                                                , hextoraw( 'FFE1' ) -- a APP1 jpg
                                                )
    then
      t_img.color_res := 8;
      t_img.height := 1;
      t_img.width := 1;
--
      t_ind := 3;
      t_ind := t_ind + 2 + raw2num( dbms_lob.substr( t_img.pixels, 2, t_ind + 2 ) );
      loop
        buf := dbms_lob.substr( t_img.pixels, 2, t_ind );
        exit when buf = hextoraw( 'FFDA' ); -- SOS Start of Scan
        exit when buf = hextoraw( 'FFD9' ); -- EOI End Of Image
        exit when substr( rawtohex( buf ), 1, 2 ) != 'FF';
        if rawtohex( buf ) in ( 'FFD0' -- RSTn
                              , 'FFD1'
                              , 'FFD2'
                              , 'FFD3'
                              , 'FFD4'
                              , 'FFD5'
                              , 'FFD6'
                              , 'FFD7'
                              , 'FF01' -- TEM
                              )
        then
          t_ind := t_ind + 2;
        else
          if buf = hextoraw( 'FFC0' ) -- SOF0 (Start Of Frame 0) marker
          then
            t_img.color_res := raw2num( dbms_lob.substr( t_img.pixels, 1, t_ind + 4 ) );
            t_img.height := raw2num( dbms_lob.substr( t_img.pixels, 2, t_ind + 5 ) );
            t_img.width := raw2num( dbms_lob.substr( t_img.pixels, 2, t_ind + 7 ) );
          end if;
          t_ind := t_ind + 2 + raw2num( dbms_lob.substr( t_img.pixels, 2, t_ind + 2 ) );
        end if;
      end loop;
    end if;
--
    return t_img;
  end;
--
  function parse_img( p_blob in blob, p_type in varchar2 := null, p_adler32 in varchar2 := null )
  return tp_img
  is
    img tp_img;
    t_type varchar2(5) := p_type;
  begin
    if t_type is null
    then
      if rawtohex( dbms_lob.substr( p_blob, 8, 1 ) ) = '89504E470D0A1A0A'
      then
        t_type := 'png';
      else
        t_type := 'jpg';
      end if;
    end if;
--
    img := case lower( t_type )
             when 'png' then parse_png( p_blob )
             when 'jpg' then parse_jpg( p_blob )
           end;
--
    if img.width is not null
    then
      img.adler32 := nvl( p_adler32, adler32( p_blob ) );
    end if;
--
    return img;
  end;
--
  procedure init
  is
  begin
    t_ncharset := nls_charset_name( nls_charset_id( 'NCHAR_CS' ) );
    t_lan_ter  := substr( sys_context( 'userenv', 'LANGUAGE' ), 1, instr( sys_context( 'userenv', 'LANGUAGE' ), '.' ) );
    dbms_lob.createtemporary( pdf_doc, true );
    settings := null;
    objects_tab.delete;
    pages_tab.delete;
    fonts.delete;
    used_fonts.delete;
    images.delete;
    objects_tab( 0 ) := 0;
    init_core_fonts;
    set_format;
    set_margins;
    new_page;
    set_font( 'helvetica' );
  end;
--
  function get_pdf
  return blob
  is
  begin
    finish_pdf;
    return pdf_doc;
  end;
--
  procedure save_pdf
    ( p_dir in varchar2 := 'MY_DIR'
    , p_filename in varchar2 := 'my.pdf'
    )
  is
    t_fh utl_file.file_type;
    t_len pls_integer := 32767;
  begin
    t_fh := utl_file.fopen( p_dir, p_filename, 'wb' );
    finish_pdf;
    for i in 0 .. trunc( ( dbms_lob.getlength( pdf_doc ) - 1 ) / t_len )
    loop
      utl_file.put_raw( t_fh, dbms_lob.substr( pdf_doc, t_len, i * t_len + 1 ) );
    end loop;
    utl_file.fclose( t_fh );
    dbms_lob.freetemporary( pdf_doc );
  end;
--
  procedure show_pdf
  is
  begin
    finish_pdf;
    owa_util.mime_header( 'application/pdf', false );
    htp.print( 'Content-Length: ' || dbms_lob.getlength( pdf_doc ) );
    htp.print( 'Content-disposition: inline' );
    htp.print( 'Content-Description: Generated by as_xslfo2pdf' );
    owa_util.http_header_close;
    wpg_docload.download_file( pdf_doc );
    dbms_lob.freetemporary( pdf_doc );
  end;
--
  function conv2user_units( p_value in number, p_unit in varchar2 )
  return number
  is
  begin
    return case lower( p_unit )
             when 'mm'    then p_value * 72 / 25.4
             when 'cm'    then p_value * 72 / 2.54
             when 'pt'    then p_value -- also point
             when 'point' then p_value
             when 'inch'  then p_value * 72
             when 'in'    then p_value * 72 -- also inch
             when 'pica'  then p_value * 12
             when 'p'     then p_value * 12 -- also pica
             when 'pc'    then p_value * 12 -- also pica
             when 'em'    then p_value * 12 -- also pica
             when 'px'    then p_value-- pixel voorlopig op point zetten
             when 'px'    then p_value * 0.8 -- pixel
             else null
           end;
  end;
--
  procedure set_format
    ( p_format in varchar2 := 'A4'
    , p_orientation in varchar2 := 'PORTRAIT'
    )
  is
    t_tmp number;
  begin
    case upper( p_format )
      when 'A3'
      then
        settings.page_height := conv2user_units( 420, 'mm' );
        settings.page_width  := conv2user_units( 297, 'mm' );
      when 'A4'
      then
        settings.page_height := conv2user_units( 297, 'mm' );
        settings.page_width  := conv2user_units( 210, 'mm' );
      when 'A5'
      then
        settings.page_height := conv2user_units( 210, 'mm' );
        settings.page_width  := conv2user_units( 148, 'mm' );
      when 'A6'
      then
        settings.page_height := conv2user_units( 148, 'mm' );
        settings.page_width  := conv2user_units( 105, 'mm' );
      when 'LEGAL'
      then
        settings.page_height := conv2user_units( 356, 'mm' );
        settings.page_width  := conv2user_units( 216, 'mm' );
      when 'LETTER'
      then
        settings.page_height := conv2user_units( 279, 'mm' );
        settings.page_width  := conv2user_units( 216, 'mm' );
      else
        null;
    end case;
--
    case
      when upper( p_orientation ) in ( 'L', 'LANDSCAPE' )
      then
        if settings.page_height > settings.page_width
        then
          t_tmp := settings.page_height;
          settings.page_height := settings.page_width;
          settings.page_width := t_tmp;
        end if;
      when upper( p_orientation ) in ( 'P', 'PORTRAIT' )
      then
        if settings.page_height < settings.page_width
        then
          t_tmp := settings.page_height;
          settings.page_height := settings.page_width;
          settings.page_width := t_tmp;
        end if;
      else
        null;
    end case;
  end;
--
  procedure set_pagesize
    ( p_width in number
    , p_height in number
    , p_unit in varchar2 := 'cm'
    )
  is
  begin
    settings.page_width  := conv2user_units( p_width, p_unit );
    settings.page_height := conv2user_units( p_height, p_unit );
  end;
--
  procedure set_margins
    ( p_top in number := 3
    , p_left in number := 1
    , p_bottom in number := 4
    , p_right in number := 1
    , p_unit in varchar2 := 'cm'
    )
  is
  begin
    settings.margin_left   := conv2user_units( p_left, p_unit );
    settings.margin_right  := conv2user_units( p_right, p_unit );
    settings.margin_top    := conv2user_units( p_top, p_unit );
    settings.margin_bottom := conv2user_units( p_bottom, p_unit );
  end;
--
  procedure set_font
    ( p_family in varchar2
    , p_style  in varchar2 := 'N'
    , p_fontsizePt in pls_integer := null
    , p_encoding in varchar2 := 'WINDOWS-1252'
    )
  is
    t_style varchar2(100);
    t_family varchar2(100);
  begin
    if (   p_family is null
       and p_style is null
       and p_fontsizePt is null
       )
    then
      return;
    end if;
    t_style := replace(
               replace(
               replace(
               replace(
               replace( upper( p_style )
                      , 'NORMAL', 'N' )
                      , 'REGULAR', 'N' )
                      , 'BOLD', 'B' )
                      , 'ITALIC', 'I' )
                      , 'OBLIQUE', 'I' );
    t_style := nvl( t_style, case when settings.current_font is null then 'N' else fonts( settings.current_font ).style end );
    t_family := nvl( lower( p_family ), case when settings.current_font is null then 'helvetica' else fonts( settings.current_font ).family end );
    for i in fonts.first .. fonts.last
    loop
      if (   fonts( i ).family = t_family
         and fonts( i ).style = t_style
         and lower( fonts( i ).encoding ) = lower( p_encoding )
         )
      then
        settings.current_font := i;
        settings.current_fontsizePt := coalesce( p_fontsizePt, settings.current_fontsizePt, 12 );
        settings.encoding := nvl( utl_i18n.map_charset( p_encoding, utl_i18n.generic_context, utl_i18n.iana_to_oracle )
                                , settings.encoding
                                );
        used_fonts( i ) := 0;
        if pages_tab.count() > 0
        then
          add2page( 'BT /F' || i || ' '
                  || to_char_round( settings.current_fontsizePt ) || ' Tf ET'
                  );
        end if;
        exit;
      end if;
    end loop;
  end;
--
  function nclob2blob( p_txt in nclob )
  return blob
  is
  begin
    if p_txt is null or p_txt = ''
    then
      return null;
    end if;
    return utl_raw.convert( utl_raw.cast_to_raw( p_txt )
                          , t_lan_ter || settings.encoding
                          , t_lan_ter || t_ncharset
                          );
  end;
--
  procedure add2page( p_txt in blob )
  is
  begin
    dbms_lob.append( pages_tab( pages_tab.count() - 1 )
                   , p_txt
                   );
    dbms_lob.append( pages_tab( pages_tab.count() - 1 )
                   , hextoraw( '0D0A' )
                   );
  end;
--
  procedure add2page( p_txt in nclob )
  is
  begin
    add2page( nclob2blob( p_txt ) );
  end;
--
  procedure put_txt( p_x in number, p_y in number, p_txt in blob )
  is
  begin
    add2page( utl_raw.concat( utl_raw.cast_to_raw( 'BT ' )
                            , utl_raw.cast_to_raw( to_char_round( p_x ) || ' ' || to_char_round( p_y ) )
                            , utl_raw.cast_to_raw( ' Td (' )
                            , pdf_string( p_txt )
                            , utl_raw.cast_to_raw( ') Tj ET' )
                            )
            );
  end;
--
  procedure put_txt( p_x in number, p_y in number, p_txt in nclob )
  is
  begin
    if p_txt is not null
    then
      put_txt( p_x, p_y, nclob2blob( p_txt ) );
    end if;
  end;
--
  function string_width( p_txt in nclob )
  return number
  is
    t_tmp blob;
    t_width number;
    t_char pls_integer;
  begin
    if p_txt is null
    then
      return 0;
    end if;
--
    t_width := 0;
    t_tmp := nclob2blob( p_txt );
    for i in 1 .. dbms_lob.getlength( t_tmp )
    loop
      t_char := utl_raw.cast_to_binary_integer( dbms_lob.substr( t_tmp, 1, i ) );
      t_width := t_width
               + fonts( settings.current_font ).char_width_tab( t_char )
               * ( settings.current_fontsizePt / 1000 );
    end loop;
    return t_width;
  end;
--
  procedure write
    ( p_txt in nclob
    , p_x in number := null
    , p_y in number := null
    , p_line_height in number := null
    , p_start in number := null  -- left side of the available text box
    , p_width in number := null  -- width of the available text box
    , p_alignment in varchar2 := null
    )
  is
    t_x number := nvl( p_x, settings.x );
    t_y number := nvl( p_y, settings.y );
    t_line_height number := nvl( p_line_height, settings.current_fontsizePt );
    t_start number := nvl( p_start, settings.margin_right );
    t_width number := nvl( p_width
                         , settings.page_width - settings.margin_right
                         - settings.margin_left
                         );
    t_len number;
    t_cnt pls_integer;
    t_ind pls_integer;
  begin
    if p_txt is null
    then
      return;
    end if;
--
    t_ind := instrc( p_txt, chr(10) );
    if t_ind > 0
    then
      write( rtrim( substrc( p_txt, 1, t_ind - 1 ), chr(13) ), t_x, t_y, t_line_height, t_start, t_width, p_alignment );
      write( substrc( p_txt, t_ind + 1 ), t_start, t_y - t_line_height, t_line_height, t_start, t_width, p_alignment );
      return;
    end if;
    t_x := case when t_x < 0 then t_start else t_x end;
    t_y := case when t_y < 0 then settings.y - t_line_height else t_y end;
    t_len := string_width( p_txt );
    if t_len > t_width - t_x + t_start
    then
      t_cnt := 0;
      while (   instrc( p_txt, ' ', 1, t_cnt + 1 ) > 0
            and string_width( substrc( p_txt, 1, instrc( p_txt, ' ', 1, t_cnt + 1 ) - 1 ) ) <= t_width - t_x + t_start
            )
      loop
        t_cnt := t_cnt + 1;
      end loop;
      if t_cnt > 0
      then
        write( substrc( p_txt, 1, instrc( p_txt, ' ', 1, t_cnt ) - 1 ), t_x, t_y, t_line_height, t_start, t_width, p_alignment );
        write( substrc( p_txt, instrc( p_txt, ' ', 1, t_cnt ) + 1 ), null, null, t_line_height, t_start, t_width, p_alignment );
      else
        if t_x > t_start
        then
          write( p_txt, t_start, t_y - t_line_height, t_line_height, t_start, t_width, p_alignment );
        else
          t_ind := trunc( length( p_txt ) / 2 );
          write( substrc( p_txt, 1, t_ind ), t_x, t_y, t_line_height, t_start, t_width, p_alignment );
          write( substrc( p_txt, t_ind + 1 ), null, null, t_line_height, t_start, t_width, p_alignment );
        end if;
      end if;
    else
      if instr( p_alignment, 'right' ) > 0 or instr( p_alignment, 'end' ) > 0
      then
        t_x := t_start + t_width - t_len;
      elsif instr( p_alignment, 'center' ) > 0
      then
        t_x := ( t_width + t_x + t_start - string_width( p_txt ) ) / 2;
      end if;
      put_txt( t_x, t_y, p_txt );
      settings.x := t_x + t_len + string_width( ' ' );
      settings.y := t_y ;
    end if;
  end;
--
  function rgb( p_hex_rgb in varchar2 )
  return varchar2
  is
  begin
    return to_char_round( nvl( to_number( substr( ltrim( p_hex_rgb, '#' ), 1, 2 ), 'xx' ) / 255, 0 ), 5 ) || ' ' ||
           to_char_round( nvl( to_number( substr( ltrim( p_hex_rgb, '#' ), 3, 2 ), 'xx' ) / 255, 0 ), 5 ) || ' ' ||
           to_char_round( nvl( to_number( substr( ltrim( p_hex_rgb, '#' ), 5, 2 ), 'xx' ) / 255, 0 ), 5 ) || ' ';
  end;
--
  procedure set_color
    ( p_rgb in varchar2 := '000000'
    , p_backgr in boolean
    )
  is
  begin
    add2page( rgb( p_rgb ) || case when p_backgr then 'RG' else 'rg' end );
  end;
--
  procedure set_color( p_rgb in varchar2 := '000000' )
  is
  begin
    set_color( p_rgb, false );
  end;
--
  procedure set_color
    ( p_red in number := 0
    , p_green in number := 0
    , p_blue in number := 0
    )
  is
  begin
    if (   p_red between 0 and 255
       and p_blue between 0 and 255
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
  procedure set_bk_color( p_rgb in varchar2 := 'ffffff' )
  is
  begin
    set_color( p_rgb, true );
  end;
--
  procedure set_bk_color
    ( p_red in number := 255
    , p_green in number := 255
    , p_blue in number := 255
    )
  is
  begin
    if (   p_red between 0 and 255
       and p_blue between 0 and 255
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
    ( p_x in number
    , p_y in number
    , p_width in number
    , p_line_width in number := 0.5
    , p_line_color in varchar2 := '000000'
    )
  is
    t_use_color boolean;
  begin
    add2page( 'q' );
    t_use_color := substr( p_line_color, -6 ) != '000000';
    if t_use_color
    then
      set_color( p_line_color );
      set_bk_color( p_line_color );
    else
      add2page( '0 g' );
    end if;
    add2page(  to_char_round( p_x, 5 ) || ' '
            || to_char_round( p_y, 5 ) || ' '
            || to_char_round( p_width, 5 ) || ' '
            || to_char_round( p_line_width, 5 ) || ' re '
            || case when t_use_color then 'b' else 'f' end
            );
    add2page( 'Q' );
  end;
--
  procedure vertical_line
    ( p_x in number
    , p_y in number
    , p_height in number
    , p_line_width in number := 0.5
    , p_line_color in varchar2 := '000000'
    )
  is
  begin
    horizontal_line( p_x, p_y, p_line_width, p_height, p_line_color );
  end;
--
  procedure rect
    ( p_x in number
    , p_y in number
    , p_width in number
    , p_height in number
    , p_line_color in varchar2 := null
    , p_fill_color in varchar2 := null
    , p_line_width in number := 0.5
    )
  is
  begin
    add2page( 'q' );
    if substr( p_line_color, -6 ) != substr( p_fill_color, -6 )
    then
      add2page( to_char_round( p_line_width, 5 ) || ' w' );
    end if;
    if substr( p_line_color, -6 ) != '000000'
    then
      set_bk_color( p_line_color );
    else
      add2page( '0 g' );
    end if;
    if p_fill_color is not null
    then
      set_color( p_fill_color );
    end if;
    add2page(  to_char_round( p_x, 5 ) || ' '
            || to_char_round( p_y, 5 ) || ' '
            || to_char_round( p_width, 5 ) || ' '
            || to_char_round( p_height, 5 ) || ' re '
            || case when p_fill_color is null then 'S' else 'b' end
            );
    add2page( 'Q' );
  end;
--
  procedure put_image
     ( p_dir in varchar2
     , p_file_name in varchar2
     , p_x in number
     , p_y in number
     , p_width in number := null
     , p_height in number := null
     )
  is
    t_blob blob;
  begin
    t_blob := file2blob( p_dir, p_file_name );
    put_image( t_blob, p_x, p_y, p_width, p_height );
    dbms_lob.freetemporary( t_blob );
  end;
--
  procedure put_image
     ( p_url in varchar2
     , p_x in number
     , p_y in number
     , p_width in number := null
     , p_height in number := null
     )
  is
    t_blob blob;
  begin
    t_blob := httpuritype( p_url ).getblob();
    put_image( t_blob, p_x, p_y, p_width, p_height );
    dbms_lob.freetemporary( t_blob );
  end;
--
  procedure put_image
     ( p_img in blob
     , p_x in number
     , p_y in number
     , p_width in number := null
     , p_height in number := null
     )
  is
    t_ind pls_integer;
    t_adler32 varchar2(8);
  begin
    if p_img is null
    then
      return;
    end if;
    t_adler32 := adler32( p_img );
    t_ind := images.first;
    while t_ind is not null
    loop
      exit when images( t_ind ).adler32 = t_adler32;
      t_ind := images.next( t_ind );
    end loop;
--
    if t_ind is null
    then
      t_ind := images.count() + 1;
      images( t_ind ) := parse_img( p_img, p_adler32 => t_adler32 );
    end if;
--
    if images( t_ind ).adler32 is null
    then
      images.delete( t_ind );
    else
      add2page( 'q ' || to_char_round( nvl( p_width, images( t_ind ).width ) ) || ' 0 0 '
              || to_char_round( nvl( p_height, images( t_ind ).height ) ) || ' '
              || to_char_round( case when p_x > 0 then p_x else - p_x - images( t_ind ).width / 2 end ) || ' '
              || to_char_round( case when p_y > 0 then p_y else - p_y + images( t_ind ).height / 2 end ) || ' '
              || ' cm /I' || to_char( t_ind ) || ' Do Q'
              );
    end if;
  end;
--
end pdf_builder_pkg;
/

