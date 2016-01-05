create or replace package body string_util_pkg
as

  /*

  Purpose:    The package handles general string-related functionality

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.09.2006  Created
  
  */
  
  m_nls_decimal_separator        varchar2(1);


function get_nls_decimal_separator return varchar2
as
  l_returnvalue varchar2(1);
begin

  /*

  Purpose:    Get decimal separator for session

  Remarks:    The value is cached to avoid looking it up dynamically each time this function is called

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     11.05.2007  Created
  
  */

  if m_nls_decimal_separator is null then
  
    begin
      select substr(value,1,1)
      into l_returnvalue
      from nls_session_parameters
      where parameter = 'NLS_NUMERIC_CHARACTERS';
    exception
      when no_data_found then
        l_returnvalue:='.';
    end;
    
    m_nls_decimal_separator := l_returnvalue;

  end if;
    
  l_returnvalue := m_nls_decimal_separator;
    
  return l_returnvalue;
  
end get_nls_decimal_separator;


function get_str (p_msg in varchar2,
                  p_value1 in varchar2 := null,
                  p_value2 in varchar2 := null,
                  p_value3 in varchar2 := null,
                  p_value4 in varchar2 := null,
                  p_value5 in varchar2 := null,
                  p_value6 in varchar2 := null,
                  p_value7 in varchar2 := null,
                  p_value8 in varchar2 := null) return varchar2
as
  l_returnvalue t_max_pl_varchar2;
begin

  /*

  Purpose:    Return string merged with substitution values

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.09.2006  Created
  MBR     15.02.2009  Altered the debug text to display (blank) instead of %1 when p_value1 is null (SA #58851)
  
  */

  l_returnvalue:=p_msg;
  
  l_returnvalue:=replace(l_returnvalue, '%1', nvl(p_value1, '(blank)'));
  l_returnvalue:=replace(l_returnvalue, '%2', nvl(p_value2, '(blank)'));
  l_returnvalue:=replace(l_returnvalue, '%3', nvl(p_value3, '(blank)'));
  l_returnvalue:=replace(l_returnvalue, '%4', nvl(p_value4, '(blank)'));
  l_returnvalue:=replace(l_returnvalue, '%5', nvl(p_value5, '(blank)'));
  l_returnvalue:=replace(l_returnvalue, '%6', nvl(p_value6, '(blank)'));
  l_returnvalue:=replace(l_returnvalue, '%7', nvl(p_value7, '(blank)'));
  l_returnvalue:=replace(l_returnvalue, '%8', nvl(p_value8, '(blank)'));
  
  return l_returnvalue;

end get_str;


procedure add_token (p_text in out varchar2,
                     p_token in varchar2,
                     p_separator in varchar2 := g_default_separator)
as
begin

  /*

  Purpose:    add token to string

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.10.2015  Created
  
  */

  if p_text is null then
    p_text := p_token;
  else
    p_text := p_text || p_separator || p_token;
  end if;
  
end add_token;


function get_nth_token(p_text in varchar2,
                       p_num in number,
                       p_separator in varchar2 := g_default_separator) return varchar2
as
  l_pos_begin    pls_integer;
  l_pos_end      pls_integer;
  l_returnvalue  t_max_pl_varchar2;
begin

  /*

  Purpose:    get the sub-string at the Nth position 

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     27.11.2006  Created, based on Pandion code
  
  */

  -- get start- and end-positions
  
  if p_num <= 0 then
    return null;
  elsif p_num = 1 then
    l_pos_begin:=1;
  else
    l_pos_begin:=instr(p_text, p_separator, 1, p_num - 1);
  end if;

  -- separator may be the first character

  l_pos_end:=instr(p_text, p_separator, 1, p_num);

  if l_pos_end > 1 then
    l_pos_end:=l_pos_end - 1;
  end if;

  if l_pos_begin > 0 then

    -- find the last element even though it may not be terminated by separator
    if l_pos_end <= 0 then
      l_pos_end:=length(p_text);
    end if;

    -- do not include separator character in output
    if p_num = 1 then
      l_returnvalue:=substr(p_text, l_pos_begin, l_pos_end - l_pos_begin + 1);
    else
      l_returnvalue:=substr(p_text, l_pos_begin + 1, l_pos_end - l_pos_begin);
    end if;

  else
    l_returnvalue:=null;
  end if;

  return l_returnvalue;

exception
  when others then
    return null;

end get_nth_token;


function get_token_count(p_text in varchar2,
                         p_separator in varchar2 := g_default_separator) return number
as
  l_pos          pls_integer;
  l_counter      pls_integer := 0;
  l_returnvalue  number;
begin

  /*

  Purpose:    get the number of sub-strings

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     27.11.2006  Created, based on Pandion code
  
  */


  if p_text is null then
    l_returnvalue:=0;
  else

    loop
      l_pos:=instr(p_text, p_separator, 1, l_counter + 1);

      if l_pos > 0 then
        l_counter:=l_counter + 1;
      else
        exit;
      end if;

    end loop;

    l_returnvalue:=l_counter + 1;

  end if;
  
  return l_returnvalue;

end get_token_count;


function str_to_num (p_str in varchar2,
                     p_decimal_separator in varchar2 := null,
                     p_thousand_separator in varchar2 := null,
                     p_raise_error_if_parse_error in boolean := false,
                     p_value_name in varchar2 := null) return number 
as
  l_returnvalue           number;
begin

  /*

  Purpose:    convert string to number

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  FDL     03.05.2007  Created
  
  */
  
  begin
    if (p_decimal_separator is null) and (p_thousand_separator is null) then
	  l_returnvalue := to_number(p_str);
    else
      l_returnvalue := to_number(replace(replace(p_str,p_thousand_separator,''), p_decimal_separator, get_nls_decimal_separator));
    end if;
  exception
    when value_error then
      if p_raise_error_if_parse_error then
        raise_application_error (-20000, string_util_pkg.get_str('Failed to parse the string "%1" to a valid number. Using decimal separator = "%2" and thousand separator = "%3". Field name = "%4". ' || sqlerrm, p_str, p_decimal_separator, p_thousand_separator, p_value_name));
      else
        l_returnvalue := null;
      end if;
  end;
  
  return l_returnvalue;

end str_to_num;


function copy_str (p_string in varchar2,
                   p_from_pos in number := 1,
                   p_to_pos in number := null) return varchar2
as
  l_to_pos       pls_integer;
  l_returnvalue  t_max_pl_varchar2;
begin

  /*

  Purpose:    copy part of string

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.05.2007  Created
  
  */

  if (p_string is null) or (p_from_pos <= 0) then
    l_returnvalue:=null;
  else

    if p_to_pos is null then
      l_to_pos:=length(p_string);
    else
      l_to_pos:=p_to_pos;
    end if;

    if l_to_pos > length(p_string) then
      l_to_pos:=length(p_string);
    end if;

    l_returnvalue:=substr(p_string, p_from_pos, l_to_pos - p_from_pos + 1);

  end if;

  return l_returnvalue;

end copy_str;


function del_str (p_string in varchar2,
                  p_from_pos in number := 1,
                  p_to_pos in number := null) return varchar2
as
  l_to_pos       pls_integer;
  l_returnvalue  t_max_pl_varchar2;
begin

  /*

  Purpose:    remove part of string

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.05.2007  Created
  
  */

  if (p_string is null) or (p_from_pos <= 0) then
    l_returnvalue:=null;
  else

    if p_to_pos is null then
      l_to_pos:=length(p_string);
    else
      l_to_pos:=p_to_pos;
    end if;

    if l_to_pos > length(p_string) then
      l_to_pos:=length(p_string);
    end if;

    l_returnvalue:=substr(p_string, 1, p_from_pos - 1) || substr(p_string, l_to_pos + 1, length(p_string) - l_to_pos);

  end if;

  return l_returnvalue;

end del_str;


function get_param_value_from_list (p_param_name in varchar2,
                                    p_param_string in varchar2,
                                    p_param_separator in varchar2 := g_default_separator,
                                    p_value_separator in varchar2 := g_param_and_value_separator) return varchar2
as
  l_returnvalue  t_max_pl_varchar2;
  l_temp_str     t_max_pl_varchar2;
  l_begin_pos    pls_integer;
  l_end_pos      pls_integer;
begin


  /*

  Purpose:    get value from parameter list with multiple named parameters

  Remarks:    given a string of type param1=value1;param2=value2;param3=value3,
              extract the value part of the given param (specified by name)

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     16.05.2007  Created
  MBR     24.09.2015  If parameter name not specified (null), then return null
  
  */

  if p_param_name is not null then

    -- get the starting position of the param name
    l_begin_pos:=instr(p_param_string, p_param_name || p_value_separator);

    if l_begin_pos = 0 then
      l_returnvalue:=null;
    else

      -- trim off characters before param value begins, including param name
      l_temp_str:=substr(p_param_string, l_begin_pos, length(p_param_string) - l_begin_pos + 1);
      l_temp_str:=del_str(l_temp_str, 1, length(p_param_name || p_value_separator));

      -- now find the first next occurence of the character delimiting the params
      -- if delimiter not found, return the rest of the string

      l_end_pos:=instr(l_temp_str, p_param_separator);
      if l_end_pos = 0 then
        l_end_pos:=length(l_temp_str);
      else
        -- strip off delimiter
        l_end_pos:=l_end_pos - 1;
      end if;

      -- retrieve the value
      l_returnvalue:=copy_str(l_temp_str, 1, l_end_pos);

    end if;

  end if;

  return l_returnvalue;

end get_param_value_from_list;                                   


function remove_whitespace (p_str in varchar2,
                            p_preserve_single_blanks in boolean := false,
                            p_remove_line_feed in boolean := false,
                            p_remove_tab in boolean := false) return varchar2
as
  l_temp_char                    constant varchar2(1) := chr(0);
  l_returnvalue                  t_max_pl_varchar2;
begin

  /*

  Purpose:    remove all whitespace from string

  Remarks:    for preserving single blanks, see http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:13912710295209
  
              "I found this solution (...) to be really "elegant" (not to mention terse, fast, and 99.9999% complete -- 
               normally, chr(0) will fill the bill as a "safe character"."

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.06.2007  Created
  MBR     13.01.2011  Added option to remove tab characters
  
  */

  if p_preserve_single_blanks then
    l_returnvalue := trim(replace(replace(replace(p_str,' ',' ' || l_temp_char), l_temp_char || ' ',''),' ' || l_temp_char,' '));
  else
    l_returnvalue := replace(p_str, ' ', '');
  end if;
  
  if p_remove_line_feed then
    l_returnvalue := replace (l_returnvalue, g_line_feed, '');
    l_returnvalue := replace (l_returnvalue, g_carriage_return, '');
  end if;
  
  if p_remove_tab then
    l_returnvalue := replace (l_returnvalue, g_tab, '');
  end if;

  return l_returnvalue;

end remove_whitespace;


function remove_non_numeric_chars (p_str in varchar2) return varchar2
as
  l_returnvalue                  t_max_pl_varchar2;
begin

  /*

  Purpose:    remove all non-numeric characters from string

  Remarks:    leaving thousand and decimal separator values (perhaps the actual values used could have been passed as parameters)

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.06.2007  Created
  
  */
 
  l_returnvalue := regexp_replace(p_str, '[^0-9,.]' , '');
  
  return l_returnvalue;

end remove_non_numeric_chars;


function remove_non_alpha_chars (p_str in varchar2) return varchar2
as
  l_returnvalue                  t_max_pl_varchar2;
begin

  /*

  Purpose:    remove all non-alpha characters (A-Z) from string

  Remarks:    does not support non-English characters (but the regular expression could be modified to support it)

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     04.07.2007  Created
  
  */
 
  l_returnvalue := regexp_replace(p_str, '[^A-Za-z]' , '');
  
  return l_returnvalue;

end remove_non_alpha_chars;


function is_str_alpha (p_str in varchar2) return boolean
as
  l_returnvalue boolean;
begin

  /*
  
  Purpose:    returns true if string only contains alpha characters
  
  Who     Date        Description
  ------  ----------  -------------------------------------
  MJH     12.05.2015  Created
  
  */

  l_returnvalue := regexp_instr(p_str, '[^a-z|A-Z]') = 0;

  return l_returnvalue;

end is_str_alpha;
  
  
function is_str_alphanumeric (p_str in varchar2) return boolean
as
  l_returnvalue boolean;
begin

  /*

  Purpose:    returns true if string is alphanumeric

  Who     Date        Description
  ------  ----------  -------------------------------------
  MJH     12.05.2015  Created

  */

  l_returnvalue := regexp_instr(p_str, '[^a-z|A-Z|0-9]') = 0;

  return l_returnvalue;

end is_str_alphanumeric;


function is_str_empty (p_str in varchar2) return boolean
as
  l_returnvalue boolean;
begin

  /*

  Purpose:    returns true if string is "empty" (contains only whitespace characters)

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.06.2007  Created
  
  */

  if p_str is null then
    l_returnvalue := true;
  elsif remove_whitespace (p_str, false, true) = '' then
    l_returnvalue := true;
  else
    l_returnvalue := false;
  end if;
  
  return l_returnvalue;

end is_str_empty;


function is_str_number (p_str in varchar2,
                        p_decimal_separator in varchar2 := null,
                        p_thousand_separator in varchar2 := null) return boolean 
as
  l_number                number;
  l_returnvalue           boolean;
begin

  /*

  Purpose:    returns true if string is a valid number

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     04.07.2007  Created
  
  */
  
  begin
  
    if (p_decimal_separator is null) and (p_thousand_separator is null) then
      l_number := to_number(p_str);
    else
      l_number := to_number(replace(replace(p_str,p_thousand_separator,''), p_decimal_separator, get_nls_decimal_separator));
    end if;
    
    l_returnvalue := true;
    
  exception
    when others then
      l_returnvalue := false;
  end;
  
  return l_returnvalue;

end is_str_number;


function is_str_integer (p_str in varchar2) return boolean
as
  l_returnvalue boolean;
begin

  /*

  Purpose:    returns true if string is an integer

  Who     Date        Description
  ------  ----------  -------------------------------------
  MJH     12.05.2015  Created
  
  */

  l_returnvalue := regexp_instr(p_str, '[^0-9]') = 0;

  return l_returnvalue;

end is_str_integer;


function short_str (p_str in varchar2,
                    p_length in number,
                    p_truncation_indicator in varchar2 := '...') return varchar2
as
  l_returnvalue t_max_pl_varchar2;
begin

  /*

  Purpose:    returns substring and indicates if string has been truncated

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     04.07.2007  Created
  
  */

  if length(p_str) > p_length then
    l_returnvalue := substr(p_str, 1, p_length - length(p_truncation_indicator)) || p_truncation_indicator;
  else
    l_returnvalue := p_str;
  end if;
  
  return l_returnvalue;
  
end short_str;


function get_param_or_value (p_param_value_pair in varchar2,
                             p_param_or_value in varchar2 := g_param_and_value_value,
                             p_delimiter in varchar2 := g_param_and_value_separator) return varchar2
as
  l_delim_pos   pls_integer;
  l_returnvalue t_max_pl_varchar2;
begin

  /*

  Purpose:    return either name or value from name/value pair

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     18.08.2009  Created
  
  */

  l_delim_pos := instr(p_param_value_pair, p_delimiter);

  if l_delim_pos != 0 then

    if upper(p_param_or_value) = g_param_and_value_value then
      l_returnvalue:=substr(p_param_value_pair, l_delim_pos + 1, length(p_param_value_pair) - l_delim_pos);
    elsif upper(p_param_or_value) = g_param_and_value_param then
      l_returnvalue:=substr(p_param_value_pair, 1, l_delim_pos - 1);
   end if;

  end if;

  return l_returnvalue;

end get_param_or_value;


function add_item_to_list (p_item in varchar2,
                           p_list in varchar2,
                           p_separator in varchar2 := g_default_separator) return varchar2
as
  l_returnvalue t_max_pl_varchar2;
begin

  /*

  Purpose:    add item to list

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     15.12.2008  Created
  
  */
 
  if p_list is null then
    l_returnvalue := p_item;
  else
    l_returnvalue := p_list || p_separator || p_item; 
  end if; 
  
  return l_returnvalue;

end add_item_to_list;     


function str_to_bool (p_str in varchar2) return boolean
as
  l_returnvalue boolean := false;
begin

  /*

  Purpose:    convert string to boolean

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     06.01.2009  Created
  
  */
  
  if lower(p_str) in ('y', 'yes', 'true', '1') then
    l_returnvalue := true;
  end if;
  
  return l_returnvalue;

end str_to_bool;
  

function str_to_bool_str (p_str in varchar2) return varchar2
as
  l_returnvalue varchar2(1) := g_no;
begin

  /*

  Purpose:    convert string to (application-defined) boolean string

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     06.01.2009  Created
  MJH     12.05.2015  Leverage string_util_pkg.str_to_bool in order to reduce code redundancy
  
  */
  
  if str_to_bool(p_str) then
    l_returnvalue := g_yes;
  end if;
  
  return l_returnvalue;

end str_to_bool_str;


function get_pretty_str (p_str in varchar2) return varchar2
as
  l_returnvalue t_max_pl_varchar2;
begin

  /*

  Purpose:    returns "pretty" string

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     16.11.2009  Created
  
  */
  
  l_returnvalue := replace(initcap(trim(p_str)), '_', ' ');
  
  return l_returnvalue;

end get_pretty_str;


function parse_date (p_str in varchar2) return date
as
  l_returnvalue date;
  
  function try_parse_date (p_str in varchar2,
                           p_date_format in varchar2) return date
  as
    l_returnvalue date;
  begin
  
    begin
      l_returnvalue := to_date(p_str, p_date_format);
    exception
      when others then
        l_returnvalue:=null;
    end;

    return l_returnvalue;
  
  end try_parse_date;
  
begin

  /*

  Purpose:    parse string to date, accept various formats

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     16.11.2009  Created
  
  */

  -- note: Oracle handles separator characters (comma, dash, slash) interchangeably,
  --       so we don't need to duplicate the various format masks with different separators (slash, hyphen)  

  l_returnvalue := try_parse_date (p_str, 'DD.MM.RRRR HH24:MI:SS');
  l_returnvalue := coalesce(l_returnvalue, try_parse_date (p_str, 'DD.MM HH24:MI:SS'));
  l_returnvalue := coalesce(l_returnvalue, try_parse_date (p_str, 'DDMMYYYY HH24:MI:SS'));
  l_returnvalue := coalesce(l_returnvalue, try_parse_date (p_str, 'DDMMRRRR HH24:MI:SS'));
  l_returnvalue := coalesce(l_returnvalue, try_parse_date (p_str, 'YYYY.MM.DD HH24:MI:SS'));
  l_returnvalue := coalesce(l_returnvalue, try_parse_date (p_str, 'MM.YYYY'));
  l_returnvalue := coalesce(l_returnvalue, try_parse_date (p_str, 'DD.MON.RRRR HH24:MI:SS'));
  l_returnvalue := coalesce(l_returnvalue, try_parse_date (p_str, 'YYYY-MM-DD"T"HH24:MI:SS".000Z"')); -- standard XML date format
  
  return l_returnvalue;

end parse_date;


function split_str (p_str in varchar2,
                    p_delim in varchar2 := g_default_separator) return t_str_array pipelined
as
  l_str   long := p_str || p_delim;
  l_n     number;
begin

  /*

  Purpose:    split delimited string to rows

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     23.11.2009  Created
  
  */

  loop
    l_n := instr(l_str, p_delim);
    exit when (nvl(l_n,0) = 0);
    pipe row (ltrim(rtrim(substr(l_str,1,l_n-1))));
    l_str := substr(l_str, l_n +1);
  end loop;

  return;

end split_str;


function join_str (p_cursor in sys_refcursor,
                   p_delim in varchar2 := g_default_separator) return varchar2
as
  l_value        t_max_pl_varchar2;
  l_returnvalue  t_max_pl_varchar2;
begin

  /*

  Purpose:    create delimited string from cursor

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     23.11.2009  Created
  
  */

  loop

    fetch p_cursor
    into l_value;
    exit when p_cursor%notfound;
    
    if l_returnvalue is not null then
      l_returnvalue := l_returnvalue || p_delim;
    end if;
    
    l_returnvalue := l_returnvalue || l_value;
    
  end loop;

  return l_returnvalue;
    
end join_str;


function multi_replace (p_string in varchar2,
                        p_search_for in t_str_array,
                        p_replace_with in t_str_array) return varchar2
as
  l_returnvalue t_max_pl_varchar2; 
begin

  /*

  Purpose:    replace several strings

  Remarks:    see http://oraclequirks.blogspot.com/2010/01/how-fast-can-we-replace-multiple.html
              this implementation uses t_str_array type instead of index-by table, so it can be used from both SQL and PL/SQL

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.01.2011  Created
  
  */
  
  l_returnvalue := p_string;

  if p_search_for.count > 0 then
    for i in 1 .. p_search_for.count loop
      l_returnvalue := replace (l_returnvalue, p_search_for(i), p_replace_with(i));
    end loop;
  end if;

  return l_returnvalue;

end multi_replace;


function multi_replace (p_clob in clob,
                        p_search_for in t_str_array,
                        p_replace_with in t_str_array) return clob
as
  l_returnvalue clob; 
begin

  /*

  Purpose:    replace several strings (clob version)

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.01.2011  Created
  
  */
  
  l_returnvalue := p_clob;

  if p_search_for.count > 0 then
    for i in 1 .. p_search_for.count loop
      l_returnvalue := replace (l_returnvalue, p_search_for(i), p_replace_with(i));
    end loop;
  end if;

  return l_returnvalue;

end multi_replace;


function is_item_in_list (p_item in varchar2,
                          p_list in varchar2,
                          p_separator in varchar2 := g_default_separator) return boolean
as
  l_returnvalue boolean;
begin

  /*

  Purpose:    return true if item is contained in list

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     02.07.2010  Created
  
  */
 
  -- add delimiters before and after list to avoid partial match
  
  l_returnvalue := (instr(p_separator || p_list || p_separator, p_separator || p_item || p_separator) > 0) and (p_item is not null);
  
  return l_returnvalue;

end is_item_in_list;     


function randomize_array (p_array in t_str_array) return t_str_array
as
  l_swap_pos    pls_integer;
  l_value       varchar2(4000);
  l_returnvalue t_str_array := p_array;
begin

  /*

  Purpose:    randomize array of strings

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     07.07.2010  Created
  MBR     26.04.2012  Ignore empty array to avoid error
  
  */

  if l_returnvalue.count > 0 then

    for i in l_returnvalue.first .. l_returnvalue.last loop
      l_swap_pos := trunc(dbms_random.value(1, l_returnvalue.count));
      l_value := l_returnvalue(i);
      l_returnvalue (i) := l_returnvalue (l_swap_pos);
      l_returnvalue (l_swap_pos) := l_value;
    end loop;

  end if;
  
  return l_returnvalue;
  
end randomize_array;


function value_has_changed (p_old in varchar2,
                            p_new in varchar2) return boolean
as
  l_returnvalue boolean;
begin
 
  /*
 
  Purpose:      return true if two values are different
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     30.07.2010  Created
 
  */
 
  if ((p_new is null) and (p_old is not null)) or
     ((p_new is not null) and (p_old is null)) or
     (p_new <> p_old)
  then
    l_returnvalue := true;
  else
    l_returnvalue := false;
  end if;

  return l_returnvalue;
 
end value_has_changed;


function concat_array (p_array in t_str_array,
                       p_separator in varchar2 := g_default_separator) return varchar2
as
  l_returnvalue                  t_max_pl_varchar2;
begin

  /*
 
  Purpose:      concatenate non-null strings with specified separator
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.11.2015  Created
 
  */

  if p_array.count > 0 then
    for i in 1 .. p_array.count loop
      if p_array(i) is not null then
        if l_returnvalue is null then
          l_returnvalue := p_array(i);
        else
          l_returnvalue := l_returnvalue || p_separator || p_array(i);
        end if;
      end if;
    end loop;
  end if;

  return l_returnvalue;

end concat_array;


end string_util_pkg;
/

