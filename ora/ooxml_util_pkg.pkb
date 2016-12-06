create or replace package body ooxml_util_pkg
as
 
  /*
 
  Purpose:      Package handles Office Open XML (OOXML) formats, ie Office 2007 docx, xlsx, etc.
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.01.2011  Created
 
  */
  
  --g_date_format                  constant varchar2(30) := 'YYYY-MM-DD"T"HH24:MI:SS".00Z"';

  g_namespace_coreprops          constant string_util_pkg.t_max_db_varchar2 := 'xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"';
  g_namespace_extendedprops      constant string_util_pkg.t_max_db_varchar2 := 'xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"';

  g_namespace_xlsx_worksheet     constant string_util_pkg.t_max_db_varchar2 := 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
  g_namespace_xlsx_sharedstrings constant string_util_pkg.t_max_db_varchar2 := 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"';
  g_namespace_xlsx_relationships constant string_util_pkg.t_max_db_varchar2 := 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
  g_namespace_package_rels       constant string_util_pkg.t_max_db_varchar2 := 'xmlns="http://schemas.openxmlformats.org/package/2006/relationships"';
  g_namespace_pptx_slide         constant string_util_pkg.t_max_db_varchar2 := 'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"';

  g_line_break_hack              constant varchar2(10) := chr(24) || chr(164) || chr(164);
 

function get_xml (p_blob in blob,
                  p_file_name in varchar2) return xmltype
as
  l_blob        blob;
  l_clob        clob;
  l_returnvalue xmltype;
begin

  /*
 
  Purpose:      get xml file from ooxml document
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.01.2011  Created
 
  */
  
  l_blob := zip_util_pkg.get_file (p_blob, p_file_name);
  
  l_clob := sql_util_pkg.blob_to_clob (l_blob);
  
  l_returnvalue := xmltype (l_clob);
  
  return l_returnvalue;

end get_xml;


function get_worksheets_list( p_xlsx in blob ) return t_xlsx_sheet_properties
as
    l_returnvalue       t_xlsx_sheet_properties;
    l_xml               xmltype;
begin
    
    /* 
    
    Purpose:      get an array of the worksheets in the workbook
    
    Remarks:       
    
    Who     Date        Description 
    ------  ----------  -------------------------------- 
    JMW     02.03.2016  Created 
    
    */ 
    
    l_xml := get_xml( p_xlsx, 'xl/workbook.xml' );
    
    select xml.r_id, xml.sheetid, xml.name
        bulk collect into l_returnvalue
      from xmltable( xmlnamespaces( default 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
                         'http://schemas.openxmlformats.org/officeDocument/2006/relationships' AS "r" ),
                    '/workbook/sheets/sheet'
                    passing l_xml
                    columns
                        r_id varchar2(255) path '@r:id',
                        sheetid number path '@sheetId',
                        name varchar2(31) path '@name' ) xml
    where xml.r_id is not null
    order by xml.sheetid;
    
    return l_returnvalue;
    
end get_worksheets_list;


function get_docx_properties (p_docx in blob) return t_docx_properties
as
  l_returnvalue t_docx_properties;
  l_xml         xmltype;
begin

  /*
 
  Purpose:      get docx properties
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.01.2011  Created
 
  */
  
  l_xml := get_xml (p_docx, 'docProps/core.xml');
  
  l_returnvalue.core.title := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:title/text()', g_namespace_coreprops);
  l_returnvalue.core.subject := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:subject/text()', g_namespace_coreprops);   
  l_returnvalue.core.creator := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:creator/text()', g_namespace_coreprops);   
  l_returnvalue.core.keywords := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/cp:keywords/text()', g_namespace_coreprops);   
  l_returnvalue.core.description := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:description/text()', g_namespace_coreprops);   
  l_returnvalue.core.last_modified_by := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/cp:lastModifiedBy/text()', g_namespace_coreprops);   
  l_returnvalue.core.revision := xml_util_pkg.extract_value_number (l_xml, '/cp:coreProperties/cp:revision/text()', g_namespace_coreprops);   
  l_returnvalue.core.created_date := xml_util_pkg.extract_value_date (l_xml, '/cp:coreProperties/dcterms:created/text()', g_namespace_coreprops);   
  l_returnvalue.core.modified_date := xml_util_pkg.extract_value_date (l_xml, '/cp:coreProperties/dcterms:modified/text()', g_namespace_coreprops);   

  l_xml := get_xml (p_docx, 'docProps/app.xml');

  l_returnvalue.app.application := xml_util_pkg.extract_value (l_xml, '/Properties/Application/text()', g_namespace_extendedprops);
  l_returnvalue.app.app_version := xml_util_pkg.extract_value (l_xml, '/Properties/AppVersion/text()', g_namespace_extendedprops);
  l_returnvalue.app.company := xml_util_pkg.extract_value (l_xml, '/Properties/Company/text()', g_namespace_extendedprops);
  l_returnvalue.app.pages := xml_util_pkg.extract_value_number (l_xml, '/Properties/Pages/text()', g_namespace_extendedprops);
  l_returnvalue.app.words := xml_util_pkg.extract_value_number (l_xml, '/Properties/Words/text()', g_namespace_extendedprops);
  
  return l_returnvalue;

end get_docx_properties;


function get_docx_to_txt_stylesheet return varchar2
as
  l_returnvalue varchar2(32000);
begin
 
  /*
 
  Purpose:      get XSL stylesheet that transforms docx to plain text
 
  Remarks:      see http://forums.oracle.com/forums/thread.jspa?messageID=3368284087
                abbreviated quite a bit, check out original posting by "user304344" for the original
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.01.2011  Created
 
  */

  l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>'
     ||chr(10)||'<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" '
     ||chr(10)||'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
     ||chr(10)||'xmlns:v="urn:schemas-microsoft-com:vml"'
     ||chr(10)||'exclude-result-prefixes="w v">'
     ||chr(10)||'<xsl:output method="text" indent="no" encoding="UTF-8" version="1.0"/>'
     ||chr(10)||'<!-- document root -->'
     ||chr(10)||'<xsl:template match="/">'
     ||chr(10)||'<!-- root element in document --> '
     ||chr(10)||'<xsl:apply-templates select="w:document"/> '
     ||chr(10)||'</xsl:template>'
     ||chr(10)||'<!-- ****************************start document**************************** -->'
     ||chr(10)||'<xsl:template match="w:document">'
     ||chr(10)||'<xsl:for-each select="//w:p">'
     ||chr(10)||'<xsl:apply-templates select="*/w:t"/> '
     ||chr(10)||'<xsl:text>' || g_line_break_hack || '</xsl:text> '
     ||chr(10)||'</xsl:for-each> '
     ||chr(10)||'</xsl:template>'
     ||chr(10)||'<!-- get all text nodes within a para -->'
     ||chr(10)||'<xsl:template match="*/w:t">'
     ||chr(10)||'<xsl:value-of select="."/>'
     ||chr(10)||'</xsl:template>'
     ||chr(10)||'<!-- **************************** end document**************************** -->'
     ||chr(10)||'</xsl:stylesheet>';
 
  return l_returnvalue;
 
end get_docx_to_txt_stylesheet;

 
function get_docx_plaintext (p_docx in blob) return clob
as
  l_document_blob blob;
  l_document_clob clob;
  l_returnvalue clob;
begin
 
  /*
 
  Purpose:      extracts plain text from docx
 
  Remarks:      based on concepts from http://monkeyonoracle.blogspot.com/2010/03/docx-part-i-how-to-extract-document.html
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.01.2011  Created
 
  */
 
  l_document_blob := zip_util_pkg.get_file (p_docx, 'word/document.xml');
  l_document_clob := sql_util_pkg.blob_to_clob (l_document_blob);
  l_returnvalue := xml_stylesheet_pkg.transform_clob(l_document_clob, get_docx_to_txt_stylesheet);
  l_returnvalue := replace (l_returnvalue, g_line_break_hack, chr(10));
  
  return l_returnvalue;
 
end get_docx_plaintext;
 
 
function get_file_from_template (p_template in blob,
                                 p_names in t_str_array,
                                 p_values in t_str_array) return blob
as
  l_file_list                    zip_util_pkg.t_file_list;
  l_docx                         blob;
  l_blob                         blob;
  l_clob                         clob;

  l_returnvalue                  blob;
begin
 
  /*
 
  Purpose:      performs substitutions on a template
 
  Remarks:      template file can be Word (docx), Excel (xlsx), or Powerpoint (pptx)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.01.2011  Created
 
  */

  l_file_list := zip_util_pkg.get_file_list (p_template);
  
  for i in 1 .. l_file_list.count loop
  
    l_blob := zip_util_pkg.get_file (p_template, l_file_list(i));
    
    if l_file_list(i) in ('word/document.xml', 'word/footer1.xml', 'xl/sharedStrings.xml')
        or (l_file_list(i) like 'ppt/slides/slide%.xml')
        or (l_file_list(i) like 'ppt/notesSlides/notesSlide%.xml') then
    
      l_clob := sql_util_pkg.blob_to_clob (l_blob);
      l_clob := string_util_pkg.multi_replace (l_clob, p_names, p_values);
      l_blob := sql_util_pkg.clob_to_blob (l_clob);
      
    end if;

    zip_util_pkg.add_file (l_returnvalue, l_file_list(i), l_blob);

  end loop;

  zip_util_pkg.finish_zip (l_returnvalue);
 
  return l_returnvalue;
 
end get_file_from_template;
 

function get_xlsx_properties (p_xlsx in blob) return t_xlsx_properties
as
  l_returnvalue t_xlsx_properties;
  l_xml         xmltype;
begin

  /*
 
  Purpose:      get xlsx properties
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     30.01.2011  Created
 
  */
  
  l_xml := get_xml (p_xlsx, 'docProps/core.xml');
  
  l_returnvalue.core.title := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:title/text()', g_namespace_coreprops);
  l_returnvalue.core.subject := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:subject/text()', g_namespace_coreprops);   
  l_returnvalue.core.creator := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:creator/text()', g_namespace_coreprops);   
  l_returnvalue.core.keywords := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/cp:keywords/text()', g_namespace_coreprops);   
  l_returnvalue.core.description := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:description/text()', g_namespace_coreprops);   
  l_returnvalue.core.last_modified_by := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/cp:lastModifiedBy/text()', g_namespace_coreprops);   
  l_returnvalue.core.revision := xml_util_pkg.extract_value_number (l_xml, '/cp:coreProperties/cp:revision/text()', g_namespace_coreprops);   
  l_returnvalue.core.created_date := xml_util_pkg.extract_value_date (l_xml, '/cp:coreProperties/dcterms:created/text()', g_namespace_coreprops);   
  l_returnvalue.core.modified_date := xml_util_pkg.extract_value_date (l_xml, '/cp:coreProperties/dcterms:modified/text()', g_namespace_coreprops);   

  l_xml := get_xml (p_xlsx, 'docProps/app.xml');

  l_returnvalue.app.application := xml_util_pkg.extract_value (l_xml, '/Properties/Application/text()', g_namespace_extendedprops);
  l_returnvalue.app.app_version := xml_util_pkg.extract_value (l_xml, '/Properties/AppVersion/text()', g_namespace_extendedprops);
  l_returnvalue.app.company := xml_util_pkg.extract_value (l_xml, '/Properties/Company/text()', g_namespace_extendedprops);
  
  return l_returnvalue;

end get_xlsx_properties;


function get_xlsx_column_number( p_column_ref in varchar2 ) return number
as
    l_returnvalue       number;
    l_char_num          number;
    l_power             number;
    l_factor            decimal;
begin

    /*

    Purpose:      get column number from column reference

    Remarks:      

    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     11.07.2011  Created
    JMW     29.11.2016  Modified to support columns up to the limit (currently XFD or 16384)

    */

    l_power := length( p_column_ref ) - 1;

    for i in 1..length( p_column_ref ) loop
        l_char_num := ascii( substr( p_column_ref, i, 1 ));
        l_factor := ( l_char_num - 65 ) + 1;
        l_returnvalue := ( l_factor * power( 26, l_power )) + NVL( l_returnvalue, 0 );
        l_power := l_power - 1;
    end loop;

    return l_returnvalue;

end get_xlsx_column_number;


function get_xlsx_column_ref( p_column_number in number ) return varchar2
as
    l_dividend      decimal;
    l_modulo        decimal;
    l_returnvalue   varchar2(3);
begin

    /*

    Purpose:      get column reference from column number

    Remarks:      

    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     11.07.2011  Created
    JMW     29.11.2016  Modified to support columns up to the limit (currently XFD or 16384)
                         and to fix the bug where the '@' is returned at multiples of 26

    */

    l_dividend := p_column_number;

    while l_dividend > 0 loop
        l_modulo := mod( l_dividend - 1, 26 );
        l_returnvalue := to_char( chr( l_modulo + 65 )) || l_returnvalue;
        l_dividend := (( l_dividend - l_modulo ) / 26 );
    end loop;

    return l_returnvalue;

end get_xlsx_column_ref;


function get_worksheet_file_name (p_xlsx in blob,
                                  p_worksheet in varchar2) return varchar2
as
  l_relationship_id              varchar2(255);
  l_returnvalue                  string_util_pkg.t_max_pl_varchar2;
  l_xml                          xmltype;
begin
 
  /*
 
  Purpose:      get file name of worksheet based on worksheet name
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     30.01.2011  Created
 
  */
  
  l_xml := get_xml (p_xlsx, 'xl/workbook.xml');
  
  l_relationship_id := xml_util_pkg.extract_value (l_xml, '/workbook/sheets/sheet[@name="' || p_worksheet || '"]/@r:id', g_namespace_xlsx_relationships);
  
  if l_relationship_id is not null then
    l_xml := get_xml (p_xlsx, 'xl/_rels/workbook.xml.rels');
    l_returnvalue := xml_util_pkg.extract_value (l_xml, '/Relationships/Relationship[@Id="' || l_relationship_id || '"]/@Target', g_namespace_package_rels);
  end if;
  
  return l_returnvalue;  

end get_worksheet_file_name;


function get_xlsx_cell_value (p_xlsx in blob,
                              p_worksheet in varchar2,
                              p_cell in varchar2) return varchar2
as
  l_returnvalue                  string_util_pkg.t_max_pl_varchar2;
  l_file_name                    string_util_pkg.t_max_db_varchar2;
  l_type                         varchar2(20);
  l_string_index                 pls_integer;
  l_xml                          xmltype;
begin
 
  /*
 
  Purpose:      get cell value from XLSX file
 
  Remarks:      see http://msdn.microsoft.com/en-us/library/bb332058(v=office.12).aspx
  
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     30.01.2011  Created
 
  */
  
  l_file_name := get_worksheet_file_name (p_xlsx, p_worksheet);
  
  if l_file_name is null then
    raise_application_error (-20000, 'Worksheet not found!');
  end if;

  l_xml := get_xml (p_xlsx, 'xl/' || l_file_name);
  
  l_returnvalue := xml_util_pkg.extract_value (l_xml, '/worksheet/sheetData/row/c[@r="' || p_cell || '"]/v/text()', g_namespace_xlsx_worksheet);

  l_type := xml_util_pkg.extract_value (l_xml, '/worksheet/sheetData/row/c[@r="' || p_cell || '"]/@t', g_namespace_xlsx_worksheet);
  
  if l_type = 's' then
    l_string_index := to_number (l_returnvalue);
    l_xml := get_xml (p_xlsx, 'xl/sharedStrings.xml');
    l_returnvalue := xml_util_pkg.extract_value (l_xml, '/sst/si[' || (l_string_index + 1) || ']//t/text()', g_namespace_xlsx_sharedstrings);
  end if;

  return l_returnvalue;
 
end get_xlsx_cell_value;


function get_xlsx_cell_values (p_xlsx in blob,
                               p_worksheet in varchar2,
                               p_cells in t_str_array) return t_str_array
as
  l_returnvalue                  t_str_array := t_str_array ();
  l_file_name                    string_util_pkg.t_max_db_varchar2;
  l_type                         varchar2(20);
  l_string_index                 pls_integer;
  l_xml                          xmltype;
  l_shared_strings               xmltype;
begin
 
  /*
 
  Purpose:      get multiple cell values from XLSX file
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     30.01.2011  Created
 
  */
  
  l_returnvalue.extend (p_cells.count);

  l_file_name := get_worksheet_file_name (p_xlsx, p_worksheet);

  if l_file_name is null then
    raise_application_error (-20000, 'Worksheet not found!');
  end if;

  l_xml := get_xml (p_xlsx, 'xl/' || l_file_name);

  l_shared_strings := get_xml (p_xlsx, 'xl/sharedStrings.xml');
  
  for i in 1 .. p_cells.count loop
  
    l_returnvalue(i) := xml_util_pkg.extract_value (l_xml, '/worksheet/sheetData/row/c[@r="' || p_cells(i) || '"]/v/text()', g_namespace_xlsx_worksheet);

    l_type := xml_util_pkg.extract_value (l_xml, '/worksheet/sheetData/row/c[@r="' || p_cells(i) || '"]/@t', g_namespace_xlsx_worksheet);
  
    if l_type = 's' then
      l_string_index := to_number (l_returnvalue(i));
      l_returnvalue(i) := xml_util_pkg.extract_value (l_shared_strings, '/sst/si[' || (l_string_index + 1) || ']//t/text()', g_namespace_xlsx_sharedstrings);
    end if;
    
  end loop;

  return l_returnvalue;
 
end get_xlsx_cell_values;


function get_xlsx_cell (p_cell_reference in varchar2) return t_xlsx_cell
as
  l_returnvalue t_xlsx_cell;
begin
 
  /*
 
  Purpose:      get cell by string reference
 
  Remarks:      given a reference of "A42", returns "A" (column) and 42 (row) as separate values
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.03.2011  Created
 
  */
  
  if p_cell_reference is not null then

    l_returnvalue.column := rtrim(upper(p_cell_reference), '1234567890');
    l_returnvalue.row := to_number(ltrim(upper(p_cell_reference), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'));

  end if;
 
  return l_returnvalue;
 
end get_xlsx_cell;


function get_xlsx_cell_values_as_sheet (p_xlsx in blob,
                                        p_worksheet in varchar2,
                                        p_cells in t_str_array) return t_xlsx_sheet
as
  l_values                       t_str_array;
  l_cell                         t_xlsx_cell;
  l_returnvalue                  t_xlsx_sheet;
begin
 
  /*
 
  Purpose:      get multiple cell values from XLSX file
 
  Remarks:      return the values as an index-by table, allowing them to be referenced by name like this: l_sheet('A1').value 
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     28.03.2011  Created
 
  */
  
  l_values := get_xlsx_cell_values (p_xlsx, p_worksheet, p_cells);
  
  for i in 1 .. p_cells.count loop
    l_cell := get_xlsx_cell (p_cells(i));
    l_cell.value := l_values(i);
    l_returnvalue (p_cells(i)) := l_cell;
  end loop;

  return l_returnvalue;

end get_xlsx_cell_values_as_sheet;


function get_xlsx_cell_array_by_range (p_from_cell in varchar2,
                                       p_to_cell in varchar2) return t_str_array
as
  l_from_cell   t_xlsx_cell;
  l_to_cell     t_xlsx_cell;
  l_returnvalue t_str_array := t_str_array();
  
  
begin
 
  /*
 
  Purpose:      get an array of cell references by range
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.03.2011  Created
  MBR     11.07.2011  Handle two-letter column references 
 
  */
  
  l_from_cell := get_xlsx_cell (p_from_cell);
  l_to_cell := get_xlsx_cell (p_to_cell);
  
  /*
  for l_column in ascii(l_from_cell.column) .. ascii(l_to_cell.column) loop
    for l_row in l_from_cell.row .. l_to_cell.row loop
      l_returnvalue.extend;
      l_returnvalue (l_returnvalue.last) := chr(l_column) || l_row;
    end loop;
  end loop;
  */
 
  for l_column in get_xlsx_column_number (l_from_cell.column) .. get_xlsx_column_number(l_to_cell.column) loop
    for l_row in l_from_cell.row .. l_to_cell.row loop
      l_returnvalue.extend;
      l_returnvalue (l_returnvalue.last) := get_xlsx_column_ref (l_column) || l_row;
    end loop;
  end loop;

  return l_returnvalue;
 
end get_xlsx_cell_array_by_range;


function get_xlsx_number (p_str in varchar2) return number
as
  l_str         string_util_pkg.t_max_db_varchar2;
  l_e_pos       pls_integer;
  l_power       pls_integer;
  l_returnvalue number;
begin
 
  /*
 
  Purpose:      get number from Excel internal format
 
  Remarks:      note that values may not be exactly what you expect,
                see http://stackoverflow.com/questions/606730/numeric-precision-issue-in-excel-2007-when-saving-as-xml
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.03.2011  Created
  MBR     11.07.2011  Handle scientific notation
  MBR     18.05.2012  Handle exception when string fails conversion to number
 
  */
  
  l_str := p_str;
  
  l_e_pos := instr(l_str, 'E');
  
  if l_e_pos > 0 then
    l_power := to_number(substr(l_str, l_e_pos + 1)); 
    l_str := substr(l_str, 1, l_e_pos - 1);
  end if;
  
  begin
    l_returnvalue := to_number(l_str, '999999999999999999999999D99999999999999999999999999999999999999', 'NLS_NUMERIC_CHARACTERS=.,');
  exception
    when value_error then
      -- conversion failed
      l_returnvalue := null;
  end;
 
  if l_e_pos > 0 then
    l_returnvalue := l_returnvalue * power (10, l_power);
  end if; 

  return l_returnvalue;
 
end get_xlsx_number;
 
 
function get_xlsx_date (p_date_str in varchar2,
                        p_time_str in varchar2 := null) return date
as
  l_days        number;
  l_returnvalue date;
begin
 
  /*
 
  Purpose:      get date from Excel internal format
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     26.03.2011  Created
 
  */
 
  l_days := get_xlsx_number (p_date_str);
  
  if p_time_str is not null then
    l_days := l_days + get_xlsx_number (p_time_str);
  end if;
  
  l_returnvalue := to_date('01.01.1900', 'dd.mm.yyyy') + l_days - 2;

  return l_returnvalue;
 
end get_xlsx_date;


function get_pptx_properties (p_pptx in blob) return t_pptx_properties
as
  l_returnvalue t_pptx_properties;
  l_xml         xmltype;
begin

  /*
 
  Purpose:      get pptx properties
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.07.2011  Created
 
  */
  
  l_xml := get_xml (p_pptx, 'docProps/core.xml');
  
  l_returnvalue.core.title := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:title/text()', g_namespace_coreprops);
  l_returnvalue.core.subject := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:subject/text()', g_namespace_coreprops);   
  l_returnvalue.core.creator := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:creator/text()', g_namespace_coreprops);   
  l_returnvalue.core.keywords := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/cp:keywords/text()', g_namespace_coreprops);   
  l_returnvalue.core.description := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/dc:description/text()', g_namespace_coreprops);   
  l_returnvalue.core.last_modified_by := xml_util_pkg.extract_value (l_xml, '/cp:coreProperties/cp:lastModifiedBy/text()', g_namespace_coreprops);   
  l_returnvalue.core.revision := xml_util_pkg.extract_value_number (l_xml, '/cp:coreProperties/cp:revision/text()', g_namespace_coreprops);   
  l_returnvalue.core.created_date := xml_util_pkg.extract_value_date (l_xml, '/cp:coreProperties/dcterms:created/text()', g_namespace_coreprops);   
  l_returnvalue.core.modified_date := xml_util_pkg.extract_value_date (l_xml, '/cp:coreProperties/dcterms:modified/text()', g_namespace_coreprops);   

  l_xml := get_xml (p_pptx, 'docProps/app.xml');

  l_returnvalue.app.application := xml_util_pkg.extract_value (l_xml, '/Properties/Application/text()', g_namespace_extendedprops);
  l_returnvalue.app.app_version := xml_util_pkg.extract_value (l_xml, '/Properties/AppVersion/text()', g_namespace_extendedprops);
  l_returnvalue.app.company := xml_util_pkg.extract_value (l_xml, '/Properties/Company/text()', g_namespace_extendedprops);
  l_returnvalue.app.slides := xml_util_pkg.extract_value_number (l_xml, '/Properties/Slides/text()', g_namespace_extendedprops);
  l_returnvalue.app.hidden_slides := xml_util_pkg.extract_value_number (l_xml, '/Properties/HiddenSlides/text()', g_namespace_extendedprops);
  l_returnvalue.app.paragraphs := xml_util_pkg.extract_value_number (l_xml, '/Properties/Paragraphs/text()', g_namespace_extendedprops);
  l_returnvalue.app.words := xml_util_pkg.extract_value_number (l_xml, '/Properties/Words/text()', g_namespace_extendedprops);
  l_returnvalue.app.notes := xml_util_pkg.extract_value_number (l_xml, '/Properties/Notes/text()', g_namespace_extendedprops);
  l_returnvalue.app.template := xml_util_pkg.extract_value (l_xml, '/Properties/Template/text()', g_namespace_extendedprops);
  l_returnvalue.app.presentation_format := xml_util_pkg.extract_value (l_xml, '/Properties/PresentationFormat/text()', g_namespace_extendedprops);
  
  return l_returnvalue;

end get_pptx_properties;


function get_pptx_media_list (p_pptx in blob,
                              p_slide in number := null) return t_str_array
as
  l_xml         xmltype;
  l_file_list   zip_util_pkg.t_file_list;
  l_returnvalue t_str_array := t_str_array();
begin
 
  /*
 
  Purpose:      get list of media files embedded in presentation
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.07.2011  Created
  MBR     28.04.2012  Specify specific slide number to get media (images) related to that slide
 
  */

  if p_slide is not null then
  
    -- see http://msdn.microsoft.com/en-us/library/bb332455(v=office.12).aspx
  
    l_xml := get_xml (p_pptx, 'ppt/slides/_rels/slide' || p_slide || '.xml.rels');

    for l_rec in (
      select extractValue(value(t), '*/@Target', g_namespace_package_rels) as target
      from table(xmlsequence(l_xml.extract('//Relationship[@Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"]', g_namespace_package_rels))) t
      )
    loop
      l_returnvalue.extend();
      l_returnvalue(l_returnvalue.last) := replace(l_rec.target, '../media', 'ppt/media');
    end loop;
  
  else

    l_file_list := zip_util_pkg.get_file_list (p_pptx);

    for i in 1 .. l_file_list.count loop
    
      if substr(l_file_list(i), 1, 10) = 'ppt/media/' then
        l_returnvalue.extend();
        l_returnvalue(l_returnvalue.last) := l_file_list(i);
      end if;

    end loop;
    
  end if;
 
  return l_returnvalue;
 
end get_pptx_media_list;
 
 
function get_pptx_to_txt_stylesheet return varchar2
as
  l_returnvalue varchar2(32000);
begin
 
  /*
 
  Purpose:      get XSL stylesheet that transforms pptx to plain text
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.07.2011  Created
 
  */

  l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" ' || g_namespace_pptx_slide || '>
    <xsl:template match="/">
      <xsl:for-each select="//a:r">
        <xsl:value-of select="a:t"/><xsl:text>' || g_line_break_hack || '</xsl:text>
      </xsl:for-each>
    </xsl:template>
  </xsl:stylesheet>';
  
  return l_returnvalue;
 
end get_pptx_to_txt_stylesheet;


function get_pptx_plaintext (p_pptx in blob,
                             p_slide in number := null,
                             p_note in number := null) return clob
as
  l_null_argument_exception exception;   --  ORA-30625: method dispatch on NULL SELF argument is disallowed
  pragma exception_init (l_null_argument_exception, -30625);
  l_document_blob blob;
  l_document_clob clob;
  l_returnvalue clob;
begin
 
  /*
 
  Purpose:      get plain text from slide
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     11.07.2011  Created
  MBR     08.07.2011  Handle empty slides
 
  */
  
  if p_note is not null then
    l_document_blob := zip_util_pkg.get_file (p_pptx, 'ppt/notesSlides/notesSlide' || p_note || '.xml');
  elsif p_slide is not null then
    l_document_blob := zip_util_pkg.get_file (p_pptx, 'ppt/slides/slide' || p_slide || '.xml');
  end if;

  if l_document_blob is not null then
    l_document_clob := sql_util_pkg.blob_to_clob (l_document_blob);
    begin
      l_returnvalue := xml_stylesheet_pkg.transform_clob(l_document_clob, get_pptx_to_txt_stylesheet);
    exception
      when l_null_argument_exception then
        l_returnvalue := null;
    end;
    l_returnvalue := replace (l_returnvalue, g_line_break_hack, chr(10));
  else
    l_returnvalue := 'Slide or note must be specified.';
  end if;

  return l_returnvalue;
 
end get_pptx_plaintext;


end ooxml_util_pkg;
/
