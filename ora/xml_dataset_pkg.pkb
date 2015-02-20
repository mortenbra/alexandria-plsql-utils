create or replace package body xml_dataset_pkg
as
 
  /*
 
  Purpose:      Package handles conversion of dataset (query or ref cursor) to and from XML
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.11.2007  Created
 
  */
  
  g_container_name               constant varchar2(30) := 'MY_CONTAINER';
 
 
function get_xml (p_query in varchar2,
                  p_param_names in t_str_array := null,
                  p_param_values in t_str_array := null) return clob
as
  l_context        dbms_xmlgen.ctxhandle;
  l_return_value   clob;
begin
 
  /*
 
  Purpose:      returns query result as XML of CLOB datatype
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.11.2007  Created
 
  */
 
  l_context := dbms_xmlgen.newcontext(p_query);

  if p_param_names is not null then
    for i in 1..p_param_names.count loop
      dbms_xmlgen.setbindvalue(l_context, p_param_names(i), p_param_values(i));
    end loop;
  end if;
  
  l_return_value:=dbms_xmlgen.getxml (l_context);
  
  dbms_xmlgen.closecontext (l_context);

  return l_return_value;
 
end get_xml;
 
 
function get_xmltype (p_query in varchar2,
                      p_param_names in t_str_array := null,
                      p_param_values in t_str_array := null) return xmltype
as
  l_context        dbms_xmlgen.ctxhandle;
  l_return_value   xmltype;
begin
 
  /*
 
  Purpose:      returns query result as XML of XMLType datatype
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.11.2007  Created
 
  */
 
  l_context := dbms_xmlgen.newcontext(p_query);

  if p_param_names is not null then
    for i in 1..p_param_names.count loop
      dbms_xmlgen.setbindvalue (l_context, p_param_names(i), p_param_values(i));
    end loop;
  end if;
  
  l_return_value := dbms_xmlgen.getxmltype (l_context);
  
  dbms_xmlgen.closecontext (l_context);

  return l_return_value;
 
end get_xmltype;
 
 
function get_xml (p_ref_cursor in sys_refcursor,
                  p_max_rows in number := null) return clob
as
  l_ctx            dbms_xmlgen.ctxhandle;
  l_returnvalue    clob;
begin
 
  /*
 
  Purpose:      returns ref cursor as XML of CLOB datatype
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.11.2010  Created
 
  */
 
  l_ctx := dbms_xmlgen.newcontext (p_ref_cursor);
  
  dbms_xmlgen.setnullhandling (l_ctx, dbms_xmlgen.empty_tag);
  
  if p_max_rows is not null then
    dbms_xmlgen.setmaxrows (l_ctx, p_max_rows);
  end if;

  l_returnvalue := dbms_xmlgen.getxml (l_ctx, dbms_xmlgen.none);
  
  dbms_xmlgen.closecontext (l_ctx);
  
  close p_ref_cursor;
  
  return l_returnvalue;
 
end get_xml;
 
 
function get_xmltype (p_ref_cursor in sys_refcursor,
                      p_max_rows in number := null) return xmltype
as
  l_ctx            dbms_xmlgen.ctxhandle;
  l_returnvalue    xmltype;
begin
 
  /*
 
  Purpose:      returns ref cursor as XML of XMLType datatype
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.11.2010  Created
 
  */
 
  l_ctx := dbms_xmlgen.newcontext (p_ref_cursor);
  
  dbms_xmlgen.setnullhandling (l_ctx, dbms_xmlgen.empty_tag);
  
  if p_max_rows is not null then
    dbms_xmlgen.setmaxrows (l_ctx, p_max_rows);
  end if;

  l_returnvalue := dbms_xmlgen.getxmltype (l_ctx, dbms_xmlgen.none);
  
  dbms_xmlgen.closecontext (l_ctx);
  
  close p_ref_cursor;
  
  return l_returnvalue;
 
end get_xmltype;


function insert_xml (p_table_name in varchar2,
                     p_xml in clob) return number
as
  l_context       dbms_xmlstore.ctxtype;
  l_return_value  number;
begin
 
  /*
 
  Purpose:      insert to table based on XML document, returns number of rows inserted
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.11.2007  Created
 
  */
 
  l_context := dbms_xmlstore.newcontext (upper(p_table_name));
  l_return_value := dbms_xmlstore.insertxml (l_context, p_xml);
  dbms_xmlstore.closecontext (l_context);
  
  return l_return_value;
 
end insert_xml;
 
 
function insert_xml (p_table_name in varchar2,
                     p_xml in xmltype) return number
as
  l_return_value  number;
begin
 
  /*
 
  Purpose:      insert to table based on XML document, returns number of rows inserted
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.11.2007  Created
 
  */
 

  l_return_value := insert_xml (p_table_name, p_xml.getclobval());
  
  return l_return_value;
 
end insert_xml;
 

procedure insert_xml (p_table_name in varchar2,
                      p_xml in clob) 
as
  l_rows number;
begin
 
  /*
 
  Purpose:      insert to table based on XML document
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.11.2007  Created
 
  */
 
  l_rows := insert_xml (p_table_name, p_xml);
 
end insert_xml;
 
 
procedure insert_xml (p_table_name in varchar2,
                      p_xml in xmltype) 
as
  l_rows number;
begin
 
  /*
 
  Purpose:      insert to table based on XML document
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.11.2007  Created
 
  */
 
  l_rows := insert_xml (p_table_name, p_xml);
 
end insert_xml;


function add_to_container (p_doc in clob,
                           p_xml in clob,
                           p_nodename in varchar2) return clob
as

  l_returnvalue                  clob;

  l_dom_doc                      dbms_xmldom.domdocument;
  l_new_dom_doc                  dbms_xmldom.domdocument;
  l_node                         dbms_xmldom.domnode;
  l_new_node                     dbms_xmldom.domnode;
  l_import_node                  dbms_xmldom.domnode;
  l_location_element             dbms_xmldom.domelement;

begin

  /*
 
  Purpose:      append dataset to xml
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     09.11.2007  Created
  MBR     07.12.2010  Handle empty datasets
 
  */
  
  l_dom_doc := xml_util_pkg.get_dom_document (p_doc);

  l_node := dbms_xslprocessor.selectsinglenode(dbms_xmldom.makenode(l_dom_doc), '/' || g_container_name || '/DOCUMENT_CONTENTS');
  
  if dbms_lob.getlength (p_xml) > 0 then
  
    l_new_dom_doc := xml_util_pkg.get_dom_document ('<' || p_nodename || '>' || xmltype(p_xml).extract('/').getclobval() || '</' || p_nodename || '>');
    l_location_element := dbms_xmldom.getdocumentelement (l_new_dom_doc);
  
    l_import_node := dbms_xmldom.importnode(l_dom_doc, dbms_xmldom.makenode (l_location_element), true);
    l_node := dbms_xmldom.appendchild (l_node, l_import_node);
  
    dbms_lob.createtemporary (l_returnvalue, false, dbms_lob.session);
    dbms_xmldom.writetoclob (l_dom_doc, l_returnvalue);
    
  else
    l_returnvalue := p_doc;
  end if;

  return l_returnvalue;
 
end add_to_container;


function get_from_container (p_clob in clob,
                             p_nodename in varchar2) return clob
as

  l_dom_doc                     dbms_xmldom.domdocument;
  l_dataset_node                dbms_xmldom.domnode;

  l_returnvalue                 clob;
  
  
begin

  /*
 
  Purpose:       extracts a dataset from a container
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.11.2007  Created
 
  */
  
  l_dom_doc := xml_util_pkg.get_dom_document (p_clob);
  l_dataset_node := dbms_xslprocessor.selectsinglenode(dbms_xmldom.makenode(l_dom_doc), '/' || g_container_name || '/DOCUMENT_CONTENTS/' || p_nodename || '/ROWSET');

  dbms_lob.createtemporary (l_returnvalue, false, dbms_lob.session);
  dbms_xmldom.writetoclob (l_dataset_node, l_returnvalue);
  
  return l_returnvalue;

end get_from_container;


function new_container (p_type in varchar2,
                        p_version in varchar2 := '1.0') return clob
as
  l_returnvalue                  clob;
begin

  /*
 
  Purpose:      creates a new container
 
  Remarks:      date format is not set specifically (assume you use the same NLS settings for import/export of data)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.11.2007  Created
  MBR     19.12.2007  Added some properties to document header
 
  */

  l_returnvalue := '<?xml version="1.0"?>';

  l_returnvalue := l_returnvalue || '<' || g_container_name || '>';

  l_returnvalue := l_returnvalue || '<DOCUMENT_PROPERTIES>';
  l_returnvalue := l_returnvalue || '<DOCUMENT_TYPE>' || p_type || '</DOCUMENT_TYPE>';
  l_returnvalue := l_returnvalue || '<DOCUMENT_VERSION>' || p_version || '</DOCUMENT_VERSION>';
  l_returnvalue := l_returnvalue || '<DOCUMENT_DATE>' || sysdate || '</DOCUMENT_DATE>';
  l_returnvalue := l_returnvalue || '</DOCUMENT_PROPERTIES>';

  l_returnvalue := l_returnvalue || '<DOCUMENT_CONTENTS>';
  l_returnvalue := l_returnvalue || '</DOCUMENT_CONTENTS>';

  l_returnvalue := l_returnvalue || '</' || g_container_name || '>';
  
  return l_returnvalue;

end new_container;
 
end xml_dataset_pkg;
/
 

