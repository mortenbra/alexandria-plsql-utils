CREATE OR REPLACE package xml_builder_pkg
as

  /*
 
  Purpose:      Package handles building XML documents
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */
  
  -- create new document in memory 
  procedure new_document;
  
  -- get document as clob
  function get_document_as_clob return clob;
  
  -- get document as XMLType
  function get_document_as_xmltype return xmltype;

  -- write document header
  procedure document_header (p_custom_attributes in varchar2 := null);

  -- write comment
  procedure document_comment (p_text in varchar2);
  
  -- write start tag
  procedure tag_begin (p_tag_name in varchar2,
                       p_tag_attributes in varchar2 := null);  

  -- write end tag
  procedure tag_end (p_tag_name in varchar2);
  
  -- write tag
  procedure tag_value (p_tag_name in varchar2,
                       p_tag_value in varchar2,
                       p_tag_attributes in varchar2 := null);

  
end xml_builder_pkg;
/

