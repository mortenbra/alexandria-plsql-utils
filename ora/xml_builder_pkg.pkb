CREATE OR REPLACE package body xml_builder_pkg
as

  /*
 
  Purpose:      Package handles building XML documents
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */
  
  g_document_text                clob;


procedure add_text (p_text in varchar2)
as
begin

  /*
 
  Purpose:      add text
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */

  g_document_text := g_document_text || p_text;

end add_text;


procedure add_line (p_text in varchar2)
as
begin

  if g_document_text is null then
    g_document_text := g_document_text || p_text;
  else
    g_document_text := g_document_text || chr(10) || p_text;
  end if;

end add_line;


procedure new_document
as
begin

  /*
 
  Purpose:      create new document
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */
  
  dbms_lob.createtemporary (g_document_text, true, dbms_lob.session);

  g_document_text := '';

end new_document;


function get_document_as_clob return clob
as
  l_returnvalue clob;
begin

  /*
 
  Purpose:      get document as clob
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */
  
  l_returnvalue := g_document_text;

  dbms_lob.freetemporary (g_document_text);

  return l_returnvalue;

end get_document_as_clob;


function get_document_as_xmltype return xmltype
as
  l_returnvalue xmltype;
begin

  /*
 
  Purpose:      get document as clob
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */
  
  l_returnvalue := xmltype(get_document_as_clob);

  return l_returnvalue;

end get_document_as_xmltype;


procedure document_header (p_custom_attributes in varchar2 := null)
as
begin

  /*
 
  Purpose:      write document header
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */

  add_line ('<?xml version="1.0" encoding="UTF-8" ?>');

end document_header;


procedure document_comment (p_text in varchar2)
as
begin

  /*
 
  Purpose:      write comment
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */

  add_line ('<!-- ' || p_text || ' -->');

end document_comment;
  

procedure tag_begin (p_tag_name in varchar2,
                     p_tag_attributes in varchar2 := null)
as
begin

  /*
 
  Purpose:      write start tag
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */

  add_line ('<' || p_tag_name || rtrim(' ' || p_tag_attributes) || '>');

end tag_begin;  


procedure tag_end (p_tag_name in varchar2)
as
begin

  /*
 
  Purpose:      write end tag
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
 
  */
  
  add_line ('</' || p_tag_name || '>');

end tag_end;
  

procedure tag_value (p_tag_name in varchar2,
                     p_tag_value in varchar2,
                     p_tag_attributes in varchar2 := null)
as
begin

  /*
 
  Purpose:      write tag value
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.08.2004  Created
  MBR     11.05.2011  Encoding of value
 
  */
  
  add_line('<' || p_tag_name || rtrim (' ' || p_tag_attributes) || '>' || dbms_xmlgen.convert(p_tag_value, dbms_xmlgen.entity_encode) || '</' || p_tag_name || '>');

end tag_value;

  
end xml_builder_pkg;
/

