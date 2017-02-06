create or replace package ooxml_util_pkg
as
 
  /*
 
  Purpose:      Package handles Office Open XML (OOXML) formats, ie Office 2007 docx, xlsx, etc.
 
  Remarks:      see http://en.wikipedia.org/wiki/Office_Open_XML
                see http://msdn.microsoft.com/en-us/library/bb266220(v=office.12).aspx
                see http://www.infoq.com/articles/cracking-office-2007-with-java
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     25.01.2011  Created
  MBR     11.07.2011  Added Powerpoint-specific features
 
  */
  
  type t_core_properties is record (
    title varchar2(2000),
    subject varchar2(2000),
    creator varchar2(2000),
    keywords varchar2(2000),
    description varchar2(2000),
    last_modified_by varchar2(2000),
    revision number,
    created_date date,
    modified_date date
  );
  
  type t_app_docx is record (
    application varchar2(2000),
    app_version varchar2(2000),
    company varchar2(2000),
    pages number,
    words number
  );
  
  type t_docx_properties is record (
    core t_core_properties,
    app  t_app_docx
  );
 
  type t_app_xlsx is record (
    application varchar2(2000),
    app_version varchar2(2000),
    company varchar2(2000)
  );

  type t_xlsx_properties is record (
    core t_core_properties,
    app  t_app_xlsx
  );
  
  type t_app_pptx is record (
    application varchar2(2000),
    app_version varchar2(2000),
    company varchar2(2000),
    slides number,
    hidden_slides number,
    paragraphs number,
    words number,
    notes number,
    presentation_format varchar2(2000),
    template varchar2(2000)
  );
  
  type t_pptx_properties is record (
    core t_core_properties,
    app  t_app_pptx
  );

  type t_xlsx_cell is record (
    column varchar2(2),
    row    number,
    value  varchar2(4000)
  );

  type t_xlsx_sheet is table of t_xlsx_cell index by varchar2(20);
  
  type t_xlsx_sheet_attributes is record (
      r_id    varchar2(255),
      sheetid number,
      name    varchar2(31)
  );
  
  type t_xlsx_sheet_properties is table of t_xlsx_sheet_attributes index by pls_integer;
  
  -- get list of xlsx worksheets
  function get_worksheets_list( p_xlsx in blob ) return t_xlsx_sheet_properties;
  
  -- get docx properties
  function get_docx_properties (p_docx in blob) return t_docx_properties;

  -- extracts plain text from docx
  function get_docx_plaintext (p_docx in blob) return clob;
 
  -- performs substitutions on a template
  function get_file_from_template (p_template in blob,
                                   p_names in t_str_array,
                                   p_values in t_str_array) return blob;
 
  -- get XLSX properties
  function get_xlsx_properties (p_xlsx in blob) return t_xlsx_properties;

  -- get column number from column reference
  function get_xlsx_column_number (p_column_ref in varchar2) return number;

  -- get column reference from column number
  function get_xlsx_column_ref (p_column_number in number) return varchar2;

  -- get cell value from XLSX file
  function get_xlsx_cell_value (p_xlsx in blob,
                                p_worksheet in varchar2,
                                p_cell in varchar2) return varchar2;

  -- get multiple cell values from XLSX file
  function get_xlsx_cell_values (p_xlsx in blob,
                                 p_worksheet in varchar2,
                                 p_cells in t_str_array) return t_str_array;

  -- get multiple cell values from XLSX file (as sheet)
  function get_xlsx_cell_values_as_sheet (p_xlsx in blob,
                                          p_worksheet in varchar2,
                                          p_cells in t_str_array) return t_xlsx_sheet;

  -- get an array of cell references by range
  function get_xlsx_cell_array_by_range (p_from_cell in varchar2,
                                         p_to_cell in varchar2) return t_str_array;

  -- get number from Excel internal format
  function get_xlsx_number (p_str in varchar2) return number;
 
  -- get date from Excel internal format
  function get_xlsx_date (p_date_str in varchar2,
                          p_time_str in varchar2 := null) return date;

  -- get pptx properties
  function get_pptx_properties (p_pptx in blob) return t_pptx_properties;

  -- get list of media files embedded in presentation
  function get_pptx_media_list (p_pptx in blob,
                                p_slide in number := null) return t_str_array;
 
  -- get plain text from slide
  function get_pptx_plaintext (p_pptx in blob,
                               p_slide in number := null,
                               p_note in number := null) return clob;

end ooxml_util_pkg;
/