create or replace package body validation_util_pkg
as
 
  /*
 
  Purpose:      Package handles validations
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.10.2011  Created
 
  */


function is_valid_email (p_value in varchar2) return boolean
as
  l_value       varchar2(32000);
  l_returnvalue boolean;
begin
 
  /*
 
  Purpose:      returns true if value is valid email address
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.10.2011  Created
  Tim N   01.04.2016  Enhancements
 
  */

  l_returnvalue := regexp_like(p_value, regexp_util_pkg.g_exp_email_addresses);

  return l_returnvalue;

end is_valid_email;


function is_valid_email2 (p_value in varchar2) return boolean
as
begin

 /*
 
  Purpose:      backward compatibility only
 
 */

  return is_valid_email(p_value);

end is_valid_email2;


function is_valid_email_list (p_value in varchar2) return boolean
as
  l_returnvalue boolean;
begin
 
  /*
 
  Purpose:      returns true if value is valid email address list
 
  Remarks:      see http://application-express-blog.e-dba.com/?p=158 for the regular expression used
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.10.2011  Created
  Tim N   01.04.2016  Enhancements
 
  */

  l_returnvalue := regexp_like(p_value, regexp_util_pkg.g_exp_email_address_list);

  return l_returnvalue;

end is_valid_email_list;


end validation_util_pkg;
/
 


