create or replace package validation_util_pkg
as
 
  /*
 
  Purpose:      Package handles validations
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.10.2011  Created
 
  */
 
 
  -- returns true if value is valid email address
  function is_valid_email (p_value in varchar2) return boolean;

  -- returns true if value is valid email address
  function is_valid_email2 (p_value in varchar2) return boolean;

  -- returns true if value is valid email address list
  function is_valid_email_list (p_value in varchar2) return boolean;
 
end validation_util_pkg;
/

