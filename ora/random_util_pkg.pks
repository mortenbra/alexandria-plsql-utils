create or replace package random_util_pkg
as
 
  /*
 
  Purpose:      Package handles generation of random values
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
 
 
  -- get random integer
  function get_integer (p_min_value in number := null,
                        p_max_value in number := null) return number;

  -- get random date
  function get_date (p_from_date in date := null,
                     p_to_date in date := null) return date;
 
  -- get a random amount (money)
  function get_amount (p_min_value in number := null,
                       p_max_value in number := null) return number;
 
  -- get a random file name
  function get_file_name (p_max_length in number := null,
                          p_file_type in varchar2 := null) return varchar2;
 
  -- get a random file type
  function get_file_type return varchar2;
 
  -- get a random mime type
  function get_mime_type return varchar2;
 
  -- get random person name
  function get_person_name (p_gender in varchar2 := null) return varchar2;
 
  -- get random email address
  function get_email_address (p_mail_domains in t_str_array,
                              p_person_name in varchar2 := null) return varchar2;
 
  -- get random text
  function get_text (p_min_length in number := null,
                     p_max_length in number := null,
                     p_language in varchar2 := null) return varchar2;
 
  -- get random buzzword
  function get_buzzword return varchar2;
  
  -- get random business concept
  function get_business_concept return varchar2;
 
  -- get a random wait message
  function get_wait_message return varchar2;
 
  -- get a random error message
  function get_error_message return varchar2;

  -- get a random value
  function get_value (p_values in t_str_array) return varchar2;

  -- get a random password
  function get_password (p_length in number := null) return varchar2;

end random_util_pkg;
/

