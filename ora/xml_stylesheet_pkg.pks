create or replace package xml_stylesheet_pkg
as
 
  /*
 
  Purpose:      Package handles stylesheets for XML
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     10.05.2010  Created
 
  */
 
 
  -- get default XML stylesheet (based on IE stylesheet)
  function get_default_xml_stylesheet_ie return varchar2;
 
  -- get default XML stylesheet (based on FF stylesheet)
  function get_default_xml_stylesheet_ff return varchar2;

  -- transform XML via stylesheet
  function transform (p_xml in xmltype,
                      p_stylesheet in xmltype := null) return xmltype;

  -- transform XML via stylesheet (clob version)
  function transform_clob (p_clob in clob,
                           p_stylesheet in clob := null) return clob;
 
end xml_stylesheet_pkg;
/
 

