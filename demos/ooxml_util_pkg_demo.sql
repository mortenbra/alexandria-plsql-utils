-- get document properties from Word file

declare
  l_blob blob;
  l_props ooxml_util_pkg.t_docx_properties;
begin
  debug_pkg.debug_on;
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'my_word_doc.docx');
  l_props := ooxml_util_pkg.get_docx_properties (l_blob);
  debug_pkg.printf('title = %1, modified = %2, creator = %3, pages = %4', l_props.core.title, l_props.core.modified_date, l_props.core.creator, l_props.app.pages);
end;


-- extract plain text from Word 2007 (docx) file

declare
  l_blob blob;
  l_clob clob;
begin
  debug_pkg.debug_on;
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'my_word_doc.docx');
  l_clob := ooxml_util_pkg.get_docx_plaintext (l_blob);
  debug_pkg.printf(substr(l_clob, 1, 32000));
end;

-- load a template (a normal document containing #TAGS#)
-- in this case a Powerpoint file, but works for any ooxml file (Word, Excel, Powerpoint)
-- replace the tags with actual values, and save the result as a new file

declare
  l_template blob;
  l_new_file blob;
begin
  debug_pkg.debug_on;
  l_template := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'powerpoint_2007_template_3.pptx');
  l_new_file := ooxml_util_pkg.get_file_from_template (l_template, t_str_array('#PRODUCT_NAME#', '#PRODUCT_VERSION#', '#CUSTOMER#'), t_str_array('FooBar', 'v2', 'MyCompany'));
  file_util_pkg.save_blob_to_file ('DEVTEST_TEMP_DIR', 'powerpoint_2007_template_3_copy.pptx', l_new_file);
end;



-- get document properties from Excel file

declare
  l_blob blob;
  l_props ooxml_util_pkg.t_xlsx_properties;
begin
  debug_pkg.debug_on;
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'test_spreadsheet.xlsx');
  l_props := ooxml_util_pkg.get_xlsx_properties (l_blob);
  debug_pkg.printf('title = %1, modified = %2, creator = %3, application = %4', l_props.core.title, l_props.core.modified_date, l_props.core.creator, l_props.app.application);
end;


-- get single value from Excel worksheet

declare
  l_blob blob;
  l_value varchar2(255);
begin
  debug_pkg.debug_on;
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'test_spreadsheet.xlsx');
  l_value := ooxml_util_pkg.get_xlsx_cell_value (l_blob, 'Sheet1', 'C2');
  debug_pkg.printf('value = %1', l_value);
end;


-- get multiple values from Excel worksheet

declare
  l_blob blob;
  l_names  t_str_array := t_str_array('B2', 'C2', 'C3', 'C4', 'A1');
  l_values t_str_array;
begin
  debug_pkg.debug_on;
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'test_spreadsheet.xlsx');
  l_values := ooxml_util_pkg.get_xlsx_cell_values (l_blob, 'Sheet1', l_names);
  for i in 1 .. l_values.count loop
    debug_pkg.printf('count = %1, name = %2, value = %3', i, l_names(i), l_values(i));
  end loop;
end;


-- get document properties from Powerpoint file

declare
  l_blob blob;
  l_props ooxml_util_pkg.t_pptx_properties;
begin
  debug_pkg.debug_on;
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'powerpoint_2007_template.pptx');
  l_props := ooxml_util_pkg.get_pptx_properties (l_blob);
  debug_pkg.printf('title = %1, modified = %2, creator = %3, slides = %4, template = %5', l_props.core.title, l_props.core.modified_date, l_props.core.creator, l_props.app.slides, l_props.app.template);
end;


-- list media files in Powerpoint file

declare
  l_blob blob;
  l_list t_str_array;
begin
  debug_pkg.debug_on;
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'powerpoint_2007_template.pptx');
  l_list := ooxml_util_pkg.get_pptx_media_list (l_blob);
  for i in 1 .. l_list.count loop
    debug_pkg.printf('file %1 = %2', i, l_list(i));
  end loop;
end;


-- extract plain text from Powerpoint 2007 (pptx) slide

declare
  l_blob blob;
  l_clob clob;
begin
  debug_pkg.debug_on;
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'powerpoint_2007_template.pptx');
  l_clob := ooxml_util_pkg.get_pptx_plaintext (l_blob, p_slide => 2);
  debug_pkg.printf(substr(l_clob, 1, 32000));
end;
