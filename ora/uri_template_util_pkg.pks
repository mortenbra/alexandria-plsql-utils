create or replace package uri_template_util_pkg
as
 
  /*
 
  Purpose:      Package handles URI templates
 
  Remarks:      see http://tools.ietf.org/html/rfc6570
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     30.07.2012  Created
 
  */
 
  type t_dictionary is table of varchar2(4000) index by varchar2(255);
 
  -- expand URI based on template
  function expand (p_template in varchar2,
                   p_values in t_str_array) return varchar2;
 
  -- matches actual URI with list of templates
  function match (p_uri in varchar2,
                  p_templates in t_str_array) return varchar2;
 
  -- get actual names and values
  function parse (p_template in varchar2,
                  p_uri in varchar2) return t_dictionary;
 
 
end uri_template_util_pkg;
/

