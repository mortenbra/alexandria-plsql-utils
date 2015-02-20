CREATE OR REPLACE package body xml_util_pkg
as

  /*

  Purpose:    Package contains general-purpose xml related functions and procedures

  Remarks:        

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     03.05.2007  Created

  */
  

function get_dom_document (p_clob in clob) return dbms_xmldom.domdocument
as
  l_returnvalue                  dbms_xmldom.domdocument;
  l_parser                       dbms_xmlparser.parser;
begin

  /*

  Purpose:    returns a dom document from a clob

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     03.05.2007  Created
  
  */
  
  l_parser:=dbms_xmlparser.newparser;
  dbms_xmlparser.parseclob (l_parser, p_clob);
  l_returnvalue:=dbms_xmlparser.getdocument (l_parser);
  dbms_xmlparser.freeparser (l_parser);

  return l_returnvalue;  

end get_dom_document;
 
 
function get_dom_document (p_text in varchar2) return dbms_xmldom.domdocument
as
  l_returnvalue                  dbms_xmldom.domdocument;
begin
  /*

  Purpose:    returns a dom document from a string

  Remarks:    overload from the same function to allow string instead of clob as input parameter  

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     02.11.2007  Created
  
  */

  l_returnvalue := dbms_xmldom.newdomdocument(xmltype(p_text));
  
  return l_returnvalue;

end get_dom_document;


function get_node_value (p_clob in clob, 
                         p_node_path in varchar2, 
                         p_node_name in varchar2) return varchar2
as
  l_dom_document dbms_xmldom.domdocument;
  l_node         dbms_xmldom.domnode;
  l_returnvalue  string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:  Get value in a specific node

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     08.05.2007  Created

  */
  
  l_dom_document := get_dom_document(p_clob);
  l_node := dbms_xslprocessor.selectsinglenode(dbms_xmldom.makenode(l_dom_document), p_node_path);

  dbms_xslprocessor.valueof (l_node, p_node_name, l_returnvalue);
  dbms_xmldom.freenode (l_node);
  dbms_xmldom.freedocument (l_dom_document);
  
  return l_returnvalue;

end get_node_value;


function get_number (p_node in dbms_xmldom.domnode,
                     p_name in varchar2,
                     p_regional_settings in t_regional_settings := null,
                     p_raise_error_if_parse_error in boolean := false) return number
as
  l_str              string_util_pkg.t_max_pl_varchar2;
  l_returnvalue      number;
begin

  /*

  Purpose:  Get numeric value from DOM node

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.05.2007  Created

  */

  dbms_xslprocessor.valueof (p_node, p_name, l_str);
  
  l_returnvalue := string_util_pkg.str_to_num(l_str, p_regional_settings.decimal_separator, p_regional_settings.thousand_separator, p_raise_error_if_parse_error);
  
  return l_returnvalue;

end get_number;


function get_string (p_node in dbms_xmldom.domnode,
                     p_name in varchar2,
                     p_trim_str in boolean := true) return varchar2 
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:    return a string from DOM node

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     07.05.2007  Created
  MBR     08.06.2007  Added option to trim string
  
  */

  dbms_xslprocessor.valueof (p_node, p_name, l_returnvalue);
  
  if p_trim_str then
    l_returnvalue := trim (l_returnvalue);
  end if;
  
  return l_returnvalue;  

end get_string;


function tag_str (p_str in varchar2,
                  p_tag_name in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:    build tagged string

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.05.2007  Created
  
  */

  l_returnvalue:='<' || p_tag_name || '>' || p_str || '</' || p_tag_name || '>';
  
  return l_returnvalue;

end tag_str;


function get_tag_value (p_text in varchar2,
                        p_tag_name in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
  l_begin_pos   pls_integer;
  l_end_pos     pls_integer;
begin

  /*

  Purpose:    get value for given tag

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.05.2007  Created
  
  */
  
  l_begin_pos:=instr(p_text, '<' || p_tag_name || '>');
  
  if l_begin_pos > 0 then

    l_begin_pos:=l_begin_pos + length('<' || p_tag_name || '>');
    l_end_pos:=instr(p_text, '</' || p_tag_name || '>');

    -- if tag not found, get rest of string
    if l_end_pos = 0 then
      l_end_pos:=length(p_text);
    else
      l_end_pos:=l_end_pos - 1;
    end if;

    l_returnvalue:=string_util_pkg.copy_str(p_text, l_begin_pos, l_end_pos);

  else
    l_returnvalue:=null;
  end if;
  
  return l_returnvalue;
 
end get_tag_value;


function node_contains_child_data (p_node in dbms_xmldom.domnode) return boolean
as
  l_node_name   string_util_pkg.t_max_pl_varchar2;
  l_node_value  string_util_pkg.t_max_pl_varchar2;
  l_node_list   dbms_xmldom.domnodelist;
  l_returnvalue boolean := false;
begin

  /*

  Purpose:    returns true if node has child nodes with non-null values

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     13.06.2007  Created
  MBR     28.06.2007  The "getnodevalue" function does not seem to work (always returns null), using "valueof" instead
  
  */

  if dbms_xmldom.haschildnodes (p_node) then
  
    -- node has children, loop through them to check whether child nodes actually contain data
    l_node_list := dbms_xmldom.getchildnodes (p_node);
    
    for l_count in 0 .. dbms_xmldom.getlength(l_node_list) - 1 loop

      --debug_pkg.printf('node_contains_child_data: l_count = %1', l_count);

      l_node_name := dbms_xmldom.getnodename(dbms_xmldom.item(l_node_list, l_count));

      -- for some reason, getnodevalue does not work, using valueof instead
      --l_node_value := dbms_xmldom.getnodevalue(dbms_xmldom.item(l_node_list, l_count));
      
      dbms_xslprocessor.valueof (p_node, l_node_name, l_node_value);
      
      if not string_util_pkg.is_str_empty(l_node_value) then
        --debug_pkg.printf('node_contains_child_data: string was *not* empty, value = %1', l_node_value);
        l_returnvalue := true;
        exit;
      else
        --debug_pkg.printf('node_contains_child_data: string was empty, value = %1', l_node_value);
        null;
      end if;
      
    end loop;
  
  else
    --debug_pkg.printf('node_contains_child_data: no child nodes found');
    l_returnvalue := false;
  end if;
  
  return l_returnvalue;

end node_contains_child_data;


function get_tag_attr_value (p_tag in varchar2,
                             p_attr_name in varchar2,
                             p_default_value in varchar2 := null) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:    get attribute value for tag

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     07.12.2010  Created
  
  */
  
  begin
    select xmltype(p_tag).extract('//@' || p_attr_name).getstringval()
    into l_returnvalue
    from dual;
  exception
    when others then
      l_returnvalue := null;
  end;
  
  l_returnvalue := nvl(l_returnvalue, p_default_value);
  
  return l_returnvalue;

end get_tag_attr_value;


function extract_value (p_xml in xmltype,
                        p_xpath in varchar2,
                        p_namespace in varchar2 := null,
                        p_default_value in varchar2 := null) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      extract value from XML
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     27.01.2011  Created
 
  */

  begin 
    l_returnvalue := p_xml.extract(p_xpath, p_namespace).getstringval();
  exception
    when others then
      l_returnvalue := p_default_value;
  end;
 
  return l_returnvalue;
 
end extract_value;
 
 
function extract_value_date (p_xml in xmltype,
                             p_xpath in varchar2,
                             p_namespace in varchar2 := null,
                             p_default_value in date := null,
                             p_date_format in varchar2 := null) return date
as
  l_returnvalue date;
begin
 
  /*
 
  Purpose:      extract value (date) from XML
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     27.01.2011  Created
 
  */
 
  begin 
    if p_date_format is not null then
      l_returnvalue := to_date(p_xml.extract(p_xpath, p_namespace).getstringval(), p_date_format);
    else
      l_returnvalue := to_date(substr(p_xml.extract(p_xpath, p_namespace).getstringval(), 1, 19), 'YYYY-MM-DD"T"hh24:mi:ss');
    end if;
  exception
    when others then
      l_returnvalue := p_default_value;
  end;

  return l_returnvalue;
 
end extract_value_date;
 
 
function extract_value_number (p_xml in xmltype,
                               p_xpath in varchar2,
                               p_namespace in varchar2 := null,
                               p_default_value in number := null) return number
as
  l_returnvalue number;
begin
 
  /*
 
  Purpose:      extract value (number) from XML
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     27.01.2011  Created
 
  */
 
  begin 
    l_returnvalue := to_number(p_xml.extract(p_xpath, p_namespace).getstringval());
  exception
    when others then
      l_returnvalue := p_default_value;
  end;

  return l_returnvalue;
 
end extract_value_number;



end xml_util_pkg;
/
