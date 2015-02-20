create or replace package body raw_util_pkg
as
 
  /*
 
  Purpose:      Package handles utilities related to the RAW datatype
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */
  
  g_endianness                   pls_integer := utl_raw.little_endian;
 
 
procedure set_endianness (p_endianness in pls_integer) 
as
begin
 
  /*
 
  Purpose:      set endianness
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */
 
  g_endianness := p_endianness;
 
end set_endianness;
 
 
function get_endianness return pls_integer
as
  l_returnvalue pls_integer;
begin
 
  /*
 
  Purpose:      get endianness
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */
  
  l_returnvalue := g_endianness;
 
  return l_returnvalue;
 
end get_endianness;
 
 
function bit_or (p_val1 in number,
                 p_val2 in number) return number
as
  l_returnvalue number;
begin
 
  /*
 
  Purpose:      bit OR
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */
 
  l_returnvalue := p_val1 - bitand(p_val1, p_val2) + p_val2;

  return l_returnvalue;
 
end bit_or;


function bit_shift_left (p_val in number,
                         p_shift in number) return number
as
  l_returnvalue number;
begin
 
  /*
 
  Purpose:      bitwise shift left
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */

  l_returnvalue :=  p_val * power(2, p_shift);
 
  return l_returnvalue;
 
end bit_shift_left;
 
 
function bit_shift_left_bi (p_val in binary_integer,
                            p_shift in number) return binary_integer
as
  l_returnvalue binary_integer;
begin
 
  /*
 
  Purpose:      bitwise shift left (binary integer)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */

  l_returnvalue :=  p_val * power(2, p_shift);
 
  return l_returnvalue;
 
end bit_shift_left_bi;
 
 
function bit_shift_left_raw (p_val in raw,
                             p_shift in number) return raw
as
begin
 
  /*
 
  Purpose:      bitwise shift left (raw)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */

  return utl_raw.cast_from_binary_integer(bit_shift_left_bi (utl_raw.cast_to_binary_integer (p_val, g_endianness), p_shift), g_endianness);
 
end bit_shift_left_raw;
 
 
function bit_shift_right (p_val in number,
                          p_shift in number) return number
as
  l_returnvalue number;
begin
 
  /*
 
  Purpose:      bitwise shift right
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */

  l_returnvalue := trunc(p_val / power(2, p_shift));
 
  return l_returnvalue;
 
end bit_shift_right;
 
 
function bit_shift_right_bi (p_val in binary_integer,
                             p_shift in number) return binary_integer
as
  l_returnvalue binary_integer;
begin
 
  /*
 
  Purpose:      bitwise shift right (binary integer)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */

  l_returnvalue := trunc(p_val / power(2, p_shift));
 
  return l_returnvalue;
 
end bit_shift_right_bi;
 
 
function bit_shift_right_raw (p_val in raw,
                              p_shift in number) return raw
as
begin
 
  /*
 
  Purpose:      bitwise shift right (raw)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */

  return utl_raw.cast_from_binary_integer(bit_shift_right_bi (utl_raw.cast_to_binary_integer (p_val, g_endianness), p_shift), g_endianness);
 
end bit_shift_right_raw;



 
end raw_util_pkg;
/
 


