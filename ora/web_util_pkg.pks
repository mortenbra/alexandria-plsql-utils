create or replace package web_util_pkg
as
 
  /*
 
  Purpose:      Package contains various web-related utility routines
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.10.2011  Created
 
  */
 
 
  -- get domain name from email address
  function get_email_domain (p_email in varchar2) return varchar2;

  -- get escaped string with HTML line breaks
  function get_escaped_str_with_breaks (p_string in varchar2,
                                        p_escape_text_if_markup in boolean := true) return varchar2;

  -- get escaped string with HTML paragraphs
  function get_escaped_str_with_paragraph (p_string in varchar2,
                                           p_escape_text_if_markup in boolean := true,
                                           p_encode_asterisks in boolean := false,
                                           p_linkify_text in boolean := false) return varchar2;
 
  -- get local file URL
  function get_local_file_url (p_file_path in varchar2) return varchar2;
 
  -- get absolute URL
  function get_absolute_url (p_url in varchar2,
                             p_base_url in varchar2) return varchar2;
  
  -- returns true if text contains (HTML) markup
  function text_contains_markup (p_text in varchar2) return boolean;

  -- linkify text
  function linkify_text (p_text in varchar2,
                         p_attributes in varchar2 := null) return varchar2;

end web_util_pkg;
/

