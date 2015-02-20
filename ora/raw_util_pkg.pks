create or replace package raw_util_pkg
as
 
  /*
 
  Purpose:      Package handles utilities related to the RAW datatype
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.06.2011  Created
 
  */
 
 
  -- set endianness
  procedure set_endianness (p_endianness in pls_integer);
 
  -- get endianness
  function get_endianness return pls_integer;
 
  -- bit OR
  function bit_or (p_val1 in number,
                   p_val2 in number) return number;

  -- bitwise shift left
  function bit_shift_left (p_val in number,
                           p_shift in number) return number;
 
  -- bitwise shift left (binary integer)
  function bit_shift_left_bi (p_val in binary_integer,
                              p_shift in number) return binary_integer;
 
  -- bitwise shift left (raw)
  function bit_shift_left_raw (p_val in raw,
                               p_shift in number) return raw;
 
  -- bitwise shift right
  function bit_shift_right (p_val in number,
                            p_shift in number) return number;
 
  -- bitwise shift right (binary integer)
  function bit_shift_right_bi (p_val in binary_integer,
                               p_shift in number) return binary_integer;
 
  -- bitwise shift right (raw)
  function bit_shift_right_raw (p_val in raw,
                                p_shift in number) return raw;
 
end raw_util_pkg;
/

