CREATE OR REPLACE package xml_util_pkg
as

  /*

  Purpose:    Package contains general-purpose XML-related functions and procedures

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     03.05.2007  Created

  */
  
  type t_regional_settings is record (
    decimal_separator varchar2(1),
    thousand_separator varchar2(1),
    date_format varchar2(20),
    time_format varchar2(20)
  );

  
  -- returns a dom document from a clob
  function get_dom_document (p_clob in clob) return dbms_xmldom.domdocument;

  -- returns a dom document from a string
  function get_dom_document (p_text in varchar2) return dbms_xmldom.domdocument;
  
  -- get value in a specific node
  function get_node_value (p_clob in clob, 
                           p_node_path in varchar2, 
                           p_node_name in varchar2) return varchar2;
  
  -- get numeric value from DOM node
  function get_number (p_node in dbms_xmldom.domnode,
                       p_name in varchar2,
                       p_regional_settings in t_regional_settings := null,
                       p_raise_error_if_parse_error in boolean := false) return number;

  -- return a string from DOM node
  function get_string (p_node in dbms_xmldom.domnode,
                       p_name in varchar2,
                       p_trim_str in boolean := true) return varchar2;
                       
  -- build tagged string
  function tag_str (p_str in varchar2,
                    p_tag_name in varchar2) return varchar2;

  -- get value for given tag
  function get_tag_value (p_text in varchar2,
                          p_tag_name in varchar2) return varchar2;

  -- returns true if node has child nodes with non-null values
  function node_contains_child_data (p_node in dbms_xmldom.domnode) return boolean;
 
  -- get attribute value for tag
  function get_tag_attr_value (p_tag in varchar2,
                               p_attr_name in varchar2,
                               p_default_value in varchar2 := null) return varchar2;

  -- extract value from XML
  function extract_value (p_xml in xmltype,
                          p_xpath in varchar2,
                          p_namespace in varchar2 := null,
                          p_default_value in varchar2 := null) return varchar2;
 
  -- extract value (date) from XML
  function extract_value_date (p_xml in xmltype,
                               p_xpath in varchar2,
                               p_namespace in varchar2 := null,
                               p_default_value in date := null,
                               p_date_format in varchar2 := null) return date;
 
  -- extract value (number) from XML
  function extract_value_number (p_xml in xmltype,
                                 p_xpath in varchar2,
                                 p_namespace in varchar2 := null,
                                 p_default_value in number := null) return number;

end xml_util_pkg;
/

