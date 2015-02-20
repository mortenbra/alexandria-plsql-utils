create or replace package apex_util_pkg
as
 
  /*
 
  Purpose:      package provides general Apex utilities
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.06.2008  Created
 
  */
 

  g_apex_null_str                constant varchar2(6) := chr(37) || 'null' || chr(37);
  g_apex_undefined_str           constant varchar2(9) := 'undefined';
  g_apex_list_separator          constant varchar2(1) := ':';
  
  -- use these in combination with apex_util.ir_filter
  g_ir_filter_equals             constant varchar2(10) := 'EQ';
  g_ir_filter_less_than          constant varchar2(10) := 'LT';
  g_ir_filter_less_than_or_eq    constant varchar2(10) := 'LTE';
  g_ir_filter_greater_than       constant varchar2(10) := 'GT';
  g_ir_filter_greater_than_or_eq constant varchar2(10) := 'GTE';
  g_ir_filter_like               constant varchar2(10) := 'LIKE';
  g_ir_filter_null               constant varchar2(10) := 'N';
  g_ir_filter_not_null           constant varchar2(10) := 'NN';

  g_ir_reset                     constant varchar2(10) := 'RIR';

  -- get page name
  function get_page_name (p_application_id in number,
                          p_page_id in number) return varchar2;

  -- get item name for page and item
  function get_item_name (p_page_id in number,
                          p_item_name in varchar2) return varchar2;

  -- get page help text
  function get_page_help_text (p_application_id in number,
                               p_page_id in number) return varchar2;
 
   -- return apex url
  function get_apex_url (p_page_id in varchar2,
                         p_request in varchar2 := null,
                         p_item_names in varchar2 := null,
                         p_item_values in varchar2 := null,
                         p_debug in varchar2 := null,
                         p_application_id in varchar2 := null,
                         p_session_id in number := null,
                         p_clear_cache in varchar2 := null) return varchar2;
                         
   -- return apex url (simple syntax)
  function get_apex_url_simple (p_page_id in varchar2,
                                p_item_name in varchar2 := null,
                                p_item_value in varchar2 := null,
                                p_request in varchar2 := null) return varchar2;

    -- get apex url item names
  function get_apex_url_item_names (p_page_id in number,
                                    p_item_name_array in t_str_array) return varchar2;

  -- get item values
  function get_apex_url_item_values (p_item_value_array in t_str_array) return varchar2;
  
  -- get query of dynamic lov
  function get_dynamic_lov_query (p_application_id in number,
                                  p_lov_name in varchar2) return varchar2;
                                  
  -- set Apex security context
  procedure set_apex_security_context (p_schema in varchar2);
  
  -- setup Apex session context
  procedure setup_apex_session_context (p_application_id in number,
                                        p_raise_exception_if_invalid in boolean := true);
  
  -- get string value
  function get_str_value (p_str in varchar2) return varchar2;
 
  -- get number value
  function get_num_value (p_str in varchar2) return number;

  -- get date value
  function get_date_value (p_str in varchar2) return date;

  -- set Apex item value (string)
  procedure set_item (p_page_id in varchar2,
                      p_item_name in varchar2,
                      p_value in varchar2);
 
  -- set Apex item value (date)
  procedure set_date_item (p_page_id in varchar2,
                           p_item_name in varchar2,
                           p_value in date,
                           p_date_format in varchar2 := null);

  -- get Apex item value (string)
  function get_item (p_page_id in varchar2,
                     p_item_name in varchar2,
                     p_max_length in number := null) return varchar2;
 
  -- get Apex item value (number)
  function get_num_item (p_page_id in varchar2,
                         p_item_name in varchar2) return number;

  -- get Apex item value (date)
  function get_date_item (p_page_id in varchar2,
                          p_item_name in varchar2) return date;

  -- get multiple item values from page into custom record type
  procedure get_items (p_app_id in number,
                       p_page_id in number,
                       p_target in varchar2,
                       p_exclude_items in t_str_array := null);
 
  -- set multiple item values on page based on custom record type
  procedure set_items (p_app_id in number,
                       p_page_id in number,
                       p_source in varchar2,
                       p_exclude_items in t_str_array := null);

  -- return true if item is in list
  function is_item_in_list (p_item in varchar2,
                            p_list in apex_application_global.vc_arr2) return boolean;

  -- get Apex session value
  function get_apex_session_value (p_value_name in varchar2) return varchar2;


end apex_util_pkg;
/
 
