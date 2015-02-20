-- create a zip file

declare
  l_file1 blob;
  l_file2 blob;
  l_zip blob;
 
begin

  l_file1 := http_util_pkg.get_blob_from_url ('http://www.oracleimg.com/admin/images/ocom/hp/oralogo_small.gif');
  l_file2 := http_util_pkg.get_blob_from_url ('http://www.oracle.com/ocom/groups/public/@ocom/documents/webcontent/oracle-footer-tagline.gif');
 
  zip_util_pkg.add_file (l_zip, 'some_folder/some_filename.gif', l_file1);
  zip_util_pkg.add_file (l_zip, 'some_other_filename.gif', l_file2);
  zip_util_pkg.finish_zip (l_zip);
  
  zip_util_pkg.save_zip (l_zip, 'DEVTEST_TEMP_DIR', 'my_zip_file.zip');
 
end;


-- unzip files, list file names only

declare
  fl zip_util_pkg.t_file_list;
begin
  fl := zip_util_pkg.get_file_list( 'DEVTEST_TEMP_DIR', 'my_zip_file.zip' );
  if fl.count() > 0
  then
    for i in fl.first .. fl.last
    loop
      dbms_output.put_line( fl( i ) );
    end loop;
  end if;
end;
/

-- unzip files, retrieve file into blob, print info, and save it to disk

declare
  fl zip_util_pkg.t_file_list;
  l_file blob;
begin
  fl := zip_util_pkg.get_file_list( 'DEVTEST_TEMP_DIR', 'my_zip_file.zip' );
  if fl.count() > 0
  then
    for i in fl.first .. fl.last
    loop
      dbms_output.put_line ( fl( i ) );
      l_file := zip_util_pkg.GET_FILE( 'DEVTEST_TEMP_DIR', 'my_zip_file.zip', fl( i ) );
      dbms_output.put_line( ' ' || nvl( dbms_lob.getlength( l_file ), -1 ) );
      file_util_pkg.save_blob_to_file ('DEVTEST_TEMP_DIR', 'unzipped_file_' || fl(i), l_file);
    end loop;
  end if;
end;
/

-- Office 2007 files (.docx, .xlsx, etc) are in fact zip files, with contents stored as xml files
-- we can extract the xml content from the file and query it

-- see also ooxml_util_pkg

begin
  file_util_pkg.save_blob_to_file ('DEVTEST_TEMP_DIR', 'my_word_doc.docx', http_util_pkg.get_blob_from_url ('http://foobar.example/document1.docx'));
end;

select extractvalue( column_value, '*/text()')
from table( xmlsequence( xmltype( zip_util_pkg.get_file( 'DEVTEST_TEMP_DIR', 'my_word_doc.docx', 'word/document.xml' ), nls_charset_id( 'UTF8' )).extract( 'w:document/w:body/w:p/w:r/w:t', 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"' )))

