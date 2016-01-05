create or replace package string_util_pkg
as

  /*

  Purpose:    The package handles general string-related functionality

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.09.2006  Created
  
  */
  
  g_max_pl_varchar2_def          varchar2(32767);
  subtype t_max_pl_varchar2      is g_max_pl_varchar2_def%type;
  
  g_max_db_varchar2_def          varchar2(4000);
  subtype t_max_db_varchar2      is g_max_db_varchar2_def%type;

  g_default_separator            constant varchar2(1) := ';';
  g_param_and_value_separator    constant varchar2(1) := '=';
  g_param_and_value_param        constant varchar2(1) := 'P';
  g_param_and_value_value        constant varchar2(1) := 'V';
  
  g_yes                          constant varchar2(1) := 'Y';
  g_no                           constant varchar2(1) := 'N';
  
  g_line_feed                    constant varchar2(1) := chr(10);
  g_new_line                     constant varchar2(1) := chr(13);
  g_carriage_return              constant varchar2(1) := chr(13);
  g_crlf                         constant varchar2(2) := g_carriage_return || g_line_feed;
  g_tab                          constant varchar2(1) := chr(9);
  g_ampersand                    constant varchar2(1) := chr(38); 

  g_html_entity_carriage_return  constant varchar2(5) := chr(38) || '#13;';
  g_html_nbsp                    constant varchar2(6) := chr(38) || 'nbsp;'; 

  -- return string merged with substitution values
  function get_str (p_msg in varchar2,
                    p_value1 in varchar2 := null,
                    p_value2 in varchar2 := null,
                    p_value3 in varchar2 := null,
                    p_value4 in varchar2 := null,
                    p_value5 in varchar2 := null,
                    p_value6 in varchar2 := null,
                    p_value7 in varchar2 := null,
                    p_value8 in varchar2 := null) return varchar2;

  -- add token to string
  procedure add_token (p_text in out varchar2,
                       p_token in varchar2,
                       p_separator in varchar2 := g_default_separator);

  -- get the sub-string at the Nth position 
  function get_nth_token(p_text in varchar2,
                         p_num in number,
                         p_separator in varchar2 := g_default_separator) return varchar2;
  
  -- get the number of sub-strings
  function get_token_count(p_text in varchar2,
                           p_separator in varchar2 := g_default_separator) return number;

  -- convert string to number
  function str_to_num (p_str in varchar2,
                       p_decimal_separator in varchar2 := null,
                       p_thousand_separator in varchar2 := null,
                       p_raise_error_if_parse_error in boolean := false,
                       p_value_name in varchar2 := null) return number;
                       
  -- copy part of string
  function copy_str (p_string in varchar2,
                     p_from_pos in number := 1,
                     p_to_pos in number := null) return varchar2;
                     
  -- remove part of string
  function del_str (p_string in varchar2,
                    p_from_pos in number := 1,
                    p_to_pos in number := null) return varchar2;
 
  -- get value from parameter list with multiple named parameters
  function get_param_value_from_list (p_param_name in varchar2,
                                      p_param_string in varchar2,
                                      p_param_separator in varchar2 := g_default_separator,
                                      p_value_separator in varchar2 := g_param_and_value_separator) return varchar2;

  -- remove all whitespace from string
  function remove_whitespace (p_str in varchar2,
                              p_preserve_single_blanks in boolean := false,
                              p_remove_line_feed in boolean := false,
                              p_remove_tab in boolean := false) return varchar2;
                              
  -- remove all non-numeric characters from string
  function remove_non_numeric_chars (p_str in varchar2) return varchar2;

  -- remove all non-alpha characters (A-Z) from string
  function remove_non_alpha_chars (p_str in varchar2) return varchar2;

  -- returns true if string only contains alpha characters
  function is_str_alpha (p_str in varchar2) return boolean;  
  
  -- returns true if string is alphanumeric
  function is_str_alphanumeric (p_str in varchar2) return boolean;

  -- returns true if string is "empty" (contains only whitespace characters)
  function is_str_empty (p_str in varchar2) return boolean;

  -- returns true if string is a valid number
  function is_str_number (p_str in varchar2,
                          p_decimal_separator in varchar2 := null,
                          p_thousand_separator in varchar2 := null) return boolean;

  -- returns true if string is an integer
  function is_str_integer (p_str in varchar2) return boolean;

  -- returns substring and indicates if string has been truncated
  function short_str (p_str in varchar2,
                      p_length in number,
                      p_truncation_indicator in varchar2 := '...') return varchar2;

  -- return either name or value from name/value pair
  function get_param_or_value (p_param_value_pair in varchar2,
                               p_param_or_value in varchar2 := g_param_and_value_value,
                               p_delimiter in varchar2 := g_param_and_value_separator) return varchar2;

  -- add item to delimited list
  function add_item_to_list (p_item in varchar2,
                             p_list in varchar2,
                             p_separator in varchar2 := g_default_separator) return varchar2;
                             
  -- convert string to boolean
  function str_to_bool (p_str in varchar2) return boolean;

  -- convert string to boolean string
  function str_to_bool_str (p_str in varchar2) return varchar2;
  
  -- get pretty string
  function get_pretty_str (p_str in varchar2) return varchar2;

  -- parse string to date, accept various formats
  function parse_date (p_str in varchar2) return date;

  -- split delimited string to rows
  function split_str (p_str in varchar2,
                      p_delim in varchar2 := g_default_separator) return t_str_array pipelined;

  -- create delimited string from cursor
  function join_str (p_cursor in sys_refcursor,
                     p_delim in varchar2 := g_default_separator) return varchar2;

  -- replace several strings
  function multi_replace (p_string in varchar2,
                          p_search_for in t_str_array,
                          p_replace_with in t_str_array) return varchar2;

  -- replace several strings (clob version)
  function multi_replace (p_clob in clob,
                          p_search_for in t_str_array,
                          p_replace_with in t_str_array) return clob;

  -- return true if item is in list
  function is_item_in_list (p_item in varchar2,
                            p_list in varchar2,
                            p_separator in varchar2 := g_default_separator) return boolean;

  -- randomize array
  function randomize_array (p_array in t_str_array) return t_str_array;

  -- return true if two values are different
  function value_has_changed (p_old in varchar2,
                              p_new in varchar2) return boolean;

  -- concatenate non-null strings with specified separator
  function concat_array (p_array in t_str_array,
                         p_separator in varchar2 := g_default_separator) return varchar2;
                              
end string_util_pkg;
/

