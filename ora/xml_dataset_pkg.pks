create or replace package xml_dataset_pkg
as
 
  /*
 
  Purpose:      Package handles conversion of dataset (query or ref cursor) to and from XML
 
  Remarks:       
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.11.2007  Created
 
  */
 
  -- returns query result as XML clob
  function get_xml (p_query in varchar2,
                    p_param_names in t_str_array := null,
                    p_param_values in t_str_array := null) return clob;
 
  -- returns query result as XMLType
  function get_xmltype (p_query in varchar2,
                        p_param_names in t_str_array := null,
                        p_param_values in t_str_array := null) return xmltype;
 
  -- returns ref cursor as XML clob
  function get_xml (p_ref_cursor in sys_refcursor,
                    p_max_rows in number := null) return clob;

  -- returns ref cursor as XMLType
  function get_xmltype (p_ref_cursor in sys_refcursor,
                        p_max_rows in number := null) return xmltype;

  -- insert to table based on XML document, returns number of rows inserted
  function insert_xml (p_table_name in varchar2,
                       p_xml in clob) return number;
 
  -- insert to table based on XML document, returns number of rows inserted
  function insert_xml (p_table_name in varchar2,
                       p_xml in xmltype) return number;

  -- insert to table based on XML document
  procedure insert_xml (p_table_name in varchar2,
                        p_xml in clob);
 
  -- insert to table based on XML document
  procedure insert_xml (p_table_name in varchar2,
                        p_xml in xmltype);

  -- appends xml to a container                  
  function add_to_container (p_doc in  clob,
                             p_xml in clob,
                             p_nodename in varchar2) return clob;
                       
  -- extracts a dataset from a container
  function get_from_container (p_clob in clob,
                               p_nodename in varchar2) return clob;
                               
  -- returns a new document container
  function new_container (p_type in varchar2,
                          p_version in varchar2 := '1.0') return clob;
 

end xml_dataset_pkg;
/
 
