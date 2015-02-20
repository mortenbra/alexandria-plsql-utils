create or replace package body image_util_pkg
as
 
  /*
 
  Purpose:      Package handles images
 
  Remarks:      Based on image parsing code from Anton Scheffer's AS_PDF3 package
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */

  type tp_pls_tab is table of pls_integer index by pls_integer;
 

function blob2num (p_blob blob,
                   p_len integer,
                   p_pos integer) return number
is
begin
  return to_number( rawtohex( dbms_lob.substr( p_blob, p_len, p_pos ) ), 'xxxxxxxx' );
end blob2num;


function raw2num (p_value raw) return number
is
begin
  return to_number( rawtohex( p_value ), 'XXXXXXXX' );
end raw2num;


function raw2num (p_value raw,
                  p_pos pls_integer,
                  p_len pls_integer) return pls_integer
is
begin
  return to_number( rawtohex( utl_raw.substr( p_value, p_pos, p_len ) ), 'XXXXXXXX' );
end raw2num;


function adler32 (p_src in blob) return varchar2
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
  
end adler32;


function parse_jpg (p_img_blob blob) return t_image_info
is
  buf raw(4);
  t_img t_image_info;
  t_ind integer;
begin

  /*
 
  Purpose:      Parse JPG
 
  Remarks:      From Anton Scheffer's AS_PDF3 package
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */

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
  
end parse_jpg;


function parse_png (p_img_blob blob) return t_image_info
is
  t_img t_image_info;
  buf raw(32767);
  len integer;
  ind integer;
  color_type pls_integer;
begin

  /*
 
  Purpose:      Parse PNG
 
  Remarks:      From Anton Scheffer's AS_PDF3 package
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */

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
  t_img.type := g_format_png;
  t_img.nr_colors := case color_type
                       when 0 then 1
                       when 2 then 3
                       when 3 then 1
                       when 4 then 2
                       else 4
                     end;
--
  return t_img;

end parse_png;


function lzw_decompress (p_blob blob,
                         p_bits pls_integer) return blob
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

  /*
 
  Purpose:      LZW decompression
 
  Remarks:      From Anton Scheffer's AS_PDF3 package
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */

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
  
end lzw_decompress;


function parse_gif (p_img_blob blob) return t_image_info
is
  img t_image_info;
  buf raw(4000);
  ind integer;
  t_len pls_integer;
begin

  /*
 
  Purpose:      Parse GIF
 
  Remarks:      From Anton Scheffer's AS_PDF3 package
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */

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
            img.transparency_index := blob2num( p_img_blob, 1, ind + 6 );
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
  img.type := g_format_gif;
  return img;

end parse_gif;


function parse_img (p_blob in blob,
                    p_adler32 in varchar2 := null,
                    p_type in varchar2 := null) return t_image_info
is
  t_img t_image_info;
begin

  /*
 
  Purpose:      Parse image file
 
  Remarks:      From Anton Scheffer's AS_PDF3 package
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */

  t_img.type := p_type;
  if t_img.type is null
  then
    if rawtohex( dbms_lob.substr( p_blob, 8, 1 ) ) = '89504E470D0A1A0A'
    then
      t_img.type := g_format_png;
    elsif dbms_lob.substr( p_blob , 3, 1 ) = utl_raw.cast_to_raw( 'GIF' )
    then
      t_img.type := g_format_gif;
    else
      t_img.type := g_format_jpg;
    end if;
  end if;
--
  t_img := case lower( t_img.type )
             when g_format_gif then parse_gif( p_blob )
             when g_format_png then parse_png( p_blob )
             when g_format_jpg then parse_jpg( p_blob )
             else null
           end;
--
  if t_img.type is not null
  then
    t_img.adler32 := coalesce( p_adler32, adler32( p_blob ) );
  end if;
  return t_img;

end parse_img;


 
function is_image (p_file in blob,
                   p_format in varchar2 := null) return boolean
as
  l_info        t_image_info;
  l_returnvalue boolean := false;
begin
 
  /*
 
  Purpose:      returns true if blob is image
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */
  
  l_info := get_image_info (p_file);
  
  if l_info.type is not null then
  
    if p_format is null then
      l_returnvalue := l_info.type in (g_format_jpg, g_format_png, g_format_gif);
    else
      l_returnvalue := l_info.type = p_format;
    end if; 
    
  end if;
 
  return l_returnvalue;
 
end is_image;
 
 
function get_image_info (p_file in blob) return t_image_info
as
  l_returnvalue t_image_info;
begin
 
  /*
 
  Purpose:      get image information
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.06.2012  Created
 
  */
 
  l_returnvalue := parse_img (p_file);

  return l_returnvalue;
 
end get_image_info;
 
end image_util_pkg;
/
 


