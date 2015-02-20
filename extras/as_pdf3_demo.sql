
-- see http://technology.amis.nl/2012/04/11/generating-a-pdf-document-with-some-plsql-as_pdf_mini-as_pdf3/

begin
  as_pdf3.init;
  as_pdf3.write( 'Minimal usage' );
  as_pdf3.save_pdf;
end;
--
begin
  as_pdf3.init;
  as_pdf3.write( 'Some text with a newline-character included at this "
" place.' );
  as_pdf3.write( 'Normally text written with as_pdf3.write() is appended after the previous text. But the text wraps automaticly to a new line.' );
  as_pdf3.write( 'But you can place your text at any place', -1, 700 );
  as_pdf3.write( 'you want', 100, 650 );
  as_pdf3.write( 'You can even align it, left, right, or centered', p_y => 600, p_alignment => 'right' );
  as_pdf3.save_pdf;
end;
--
begin
  as_pdf3.init;
  as_pdf3.write( 'The 14 standard PDF-fonts and the WINDOWS-1252 encoding.' );
  as_pdf3.set_font( 'helvetica' );
  as_pdf3.write( 'helvetica, normal: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, 700 );
  as_pdf3.set_font( 'helvetica', 'I' );
  as_pdf3.write( 'helvetica, italic: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'helvetica', 'b' );
  as_pdf3.write( 'helvetica, bold: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'helvetica', 'BI' );
  as_pdf3.write( 'helvetica, bold italic: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'times' );
  as_pdf3.write( 'times, normal: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, 625 );
  as_pdf3.set_font( 'times', 'I' );
  as_pdf3.write( 'times, italic: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'times', 'b' );
  as_pdf3.write( 'times, bold: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'times', 'BI' );
  as_pdf3.write( 'times, bold italic: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'courier' );
  as_pdf3.write( 'courier, normal: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, 550 );
  as_pdf3.set_font( 'courier', 'I' );
  as_pdf3.write( 'courier, italic: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'courier', 'b' );
  as_pdf3.write( 'courier, bold: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'courier', 'BI' );
  as_pdf3.write( 'courier, bold italic: ' || 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
--
  as_pdf3.set_font( 'courier' );
  as_pdf3.write( 'symbol:', -1, 475 );
  as_pdf3.set_font( 'symbol' );
  as_pdf3.write( 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
  as_pdf3.set_font( 'courier' );
  as_pdf3.write( 'zapfdingbats:', -1, -1 );
  as_pdf3.set_font( 'zapfdingbats' );
  as_pdf3.write( 'The quick brown fox jumps over the lazy dog. 1234567890', -1, -1 );
--
  as_pdf3.set_font( 'times', 'N', 20 );
  as_pdf3.write( 'times, normal with fontsize 20pt', -1, 400 );
  as_pdf3.set_font( 'times', 'N', 6 );
  as_pdf3.write( 'times, normal with fontsize 5pt', -1, -1 );
  as_pdf3.save_pdf;
end;
--
declare
  x pls_integer;
begin
  as_pdf3.init;
  as_pdf3.write( 'But others fonts and encodings are possible using TrueType fontfiles.' );
  x := as_pdf3.load_ttf_font( 'MY_FONTS', 'refsan.ttf', 'CID', p_compress => false );
  as_pdf3.set_font( x, 12  );
  as_pdf3.write( 'The Windows MSReference SansSerif font contains a lot of encodings, for instance', -1, 700 );
  as_pdf3.set_font( x, 15  );
  as_pdf3.write( 'Albanian: Kush mund të lexoni këtë diçka si kjo', -1, -1 );
  as_pdf3.write( 'Croatic: Tko može citati to nešto poput ovoga', -1, -1 );
  as_pdf3.write( 'Russian: ??? ????? ????????? ??? ???-?? ????? ?????', -1, -1);
  as_pdf3.write( 'Greek: ????? µp??e? ?a d?aß?se? a?t? t? ??t? sa? a?t?', -1, -1 ); 
--
  as_pdf3.set_font( 'helvetica', 12  );
  as_pdf3.write( 'Or by using a  TrueType collection file (ttc).', -1, 600 );
  as_pdf3.load_ttc_fonts( 'MY_FONTS',  'cambria.ttc', p_embed => true, p_compress => false );
  as_pdf3.set_font( 'cambria', 15 );   -- font family
  as_pdf3.write( 'Anton, testing 1,2,3 with Cambria', -1, -1 );
  as_pdf3.set_font( 'CambriaMT', 15 );  -- fontname
  as_pdf3.write( 'Anton, testing 1,2,3 with CambriaMath', -1, -1 );
  as_pdf3.save_pdf;
end;
--
begin
  as_pdf3.init;
  for i in 1 .. 10
  loop
    as_pdf3.horizontal_line( 30, 700 - i * 15, 100, i );
  end loop;
  for i in 1 .. 10
  loop
    as_pdf3.vertical_line( 150 + i * 15, 700, 100, i );
  end loop;
  for i in 0 .. 255
  loop
    as_pdf3.horizontal_line( 330, 700 - i, 100, 2, p_line_color =>  to_char( i, 'fm0x' ) || to_char( i, 'fm0x' ) || to_char( i, 'fm0x' ) );
  end loop;
  as_pdf3.save_pdf;
end;
--
declare
  t_logo varchar2(32767) :=
'/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkS' ||
'Ew8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJ' ||
'CQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIy' ||
'MjIyMjIyMjIyMjIyMjL/wAARCABqAJYDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEA' ||
'AAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIh' ||
'MUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6' ||
'Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZ' ||
'mqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx' ||
'8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREA' ||
'AgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAV' ||
'YnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hp' ||
'anN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPE' ||
'xcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3' ||
'+iiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAoorifiX4pk' ||
'8PaCILR9t9eExxsOqL/E315AHuaUmkrs1oUZVqipw3ZU8X/FCz0KeSw02Jb2+Thy' ||
'WxHGfQkdT7D8686ufih4suGJW/jgXssUC8fnk1ydvbz3lzHb28bzTyttRF5LMa7H' ||
'Uvh+3hvRI9T1+7kUPIsf2ezUMykgnlmIHbtXI5znqtj66ng8DhFGFRJyffVv5Fnw' ||
'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';
begin
  as_pdf3.init;
  as_pdf3.put_image( to_blob( utl_encode.base64_decode( utl_raw.cast_to_raw( t_logo ) ) )
                   , 0
                   , as_pdf3.get( as_pdf3.C_GET_PAGE_HEIGHT ) - 260
                   , as_pdf3.get( as_pdf3.C_GET_PAGE_WIDTH )
                   );
  as_pdf3.write( 'jpg, gif and png images are supported.' );
  as_pdf3.write( 'And because PDF 1.3 (thats the format I use) doesn''t support alpha channels, neither does AS_PDF.', -1, -1 );
  as_pdf3.save_pdf;
end;
--
declare
  t_rc sys_refcursor;
  t_query varchar2(1000);
begin
  as_pdf3.init;
  as_pdf3.load_ttf_font( 'MY_FONTS', 'COLONNA.TTF', 'CID' );
  as_pdf3.set_page_proc( q'~
    begin    
      as_pdf3.set_font( 'helvetica', 8 );
      as_pdf3.put_txt( 10, 15, 'Page #PAGE_NR# of "PAGE_COUNT#' );
      as_pdf3.set_font( 'helvetica', 12 );
      as_pdf3.put_txt( 350, 15, 'This is a footer text' );
      as_pdf3.set_font( 'helvetica', 'B', 15 );
      as_pdf3.put_txt( 200, 780, 'This is a header text' );
      as_pdf3.put_image( 'MY_DIR', 'amis.jpg', 500, 15 );
   end;~' );
  as_pdf3.set_page_proc( q'~
    begin    
      as_pdf3.set_font( 'Colonna MT', 'N', 50 );
      as_pdf3.put_txt( 150, 200, 'Watermark Watermark Watermark', 60 );
   end;~' ); 
  t_query := 'select rownum, sysdate + level, ''example'' || level from dual connect by level <= 50'; 
  as_pdf3.query2table( t_query );
  open t_rc for t_query;
  as_pdf3.refcursor2table( t_rc );
  as_pdf3.save_pdf;
end;


declare
  ts timestamp;
begin
  ts := systimestamp;
  as_pdf3.init;
  as_pdf3.set_font( as_pdf3.load_ttf_font( as_pdf3.file2blob( 'MY_FONTS', 'arial.ttf' ), 'CID' ), 15 );
  as_pdf3.write( 'Anton, testing 1,2,3!' );
  as_pdf3.save_pdf;
  dbms_output.put_line( systimestamp - ts );
end;

