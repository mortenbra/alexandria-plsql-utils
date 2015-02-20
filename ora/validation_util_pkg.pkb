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
  l_dot_pos                      number;
  l_at_pos                       number;
  l_str_length                   number;
  l_returnvalue                  boolean := true;
begin
 
  /*
 
  Purpose:      returns true if value is valid email address
 
  Remarks:      Written by Anil Passi, see http://oracle.anilpassi.com/validate-email-pl-sql-2.html
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.10.2011  Created
  MBR     26.10.2011  Added check against multiple at signs
 
  */

  if p_value is null then
    l_returnvalue := false;
  else

    l_dot_pos := instr(p_value, '.');
    l_at_pos := instr(p_value, '@');
    
    l_str_length := length(p_value);
    
    if ((l_dot_pos = 0) or (l_at_pos = 0) or (l_dot_pos = l_at_pos + 1) or (l_at_pos = 1) or (l_at_pos = l_str_length) or (l_dot_pos = l_str_length)) then
      l_returnvalue := false;
    end if;

    if instr(substr(p_value, l_at_pos), '.') = 0 then
      l_returnvalue := false;
    end if;

    if instr(substr(p_value, l_at_pos + 1), '@') > 0 then
      l_returnvalue := false;
    end if;


  end if;  
  
  return l_returnvalue;
 
end is_valid_email;


function is_valid_email2 (p_value in varchar2) return boolean
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
 
  */
  
  if p_value is null then
    l_returnvalue := false;
  else
    l_returnvalue := regexp_replace(p_value, regexp_util_pkg.g_exp_email_addresses, null) is null;
  end if;
  
  return l_returnvalue;
 
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
 
  */
  
  if p_value is null then
    l_returnvalue := false;
  else
    l_returnvalue := regexp_replace(p_value, regexp_util_pkg.g_exp_email_address_list, null) is null;
  end if; 

  return l_returnvalue;
 
end is_valid_email_list;


end validation_util_pkg;
/
 


