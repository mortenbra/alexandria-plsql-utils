create or replace package body csv_util_pkg
as
 
  /*
 
  Purpose:      Package handles comma-separated values (CSV)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     31.03.2010  Created
  KJS     20.04.2011  Modified to allow double-quote escaping
 
  */
 
 
function csv_to_array (p_csv_line in varchar2,
                       p_separator in varchar2 := g_default_separator) return t_str_array
as
  l_returnvalue      t_str_array     := t_str_array();
  l_length           pls_integer     := length(p_csv_line);
  l_idx              binary_integer  := 1;
  l_quoted           boolean         := false;  
  l_quote  constant  varchar2(1)     := '"';
  l_start            boolean := true;
  l_current          varchar2(1 char);
  l_next             varchar2(1 char);
  l_position         pls_integer := 1;
  l_current_column   varchar2(32767);
  
  --Set the start flag, save our column value
  procedure save_column is
  begin
    l_start := true;
    l_returnvalue.extend;        
    l_returnvalue(l_idx) := l_current_column;
    l_idx := l_idx + 1;            
    l_current_column := null;
  end save_column;
  
  --Append the value of l_current to l_current_column
  procedure append_current is
  begin
    l_current_column := l_current_column || l_current;
  end append_current;
begin

  /*
 
  Purpose:      convert CSV line to array of values
 
  Remarks:      based on code from http://www.experts-exchange.com/Database/Oracle/PL_SQL/Q_23106446.html
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     31.03.2010  Created
  KJS     20.04.2011  Modified to allow double-quote escaping
  MBR     23.07.2012  Fixed issue with multibyte characters, thanks to Vadi..., see http://code.google.com/p/plsql-utils/issues/detail?id=13
 
  */

  while l_position <= l_length loop
  
    --Set our variables with the current and next characters
    l_current := substr(p_csv_line, l_position, 1);
    l_next := substr(p_csv_line, l_position + 1, 1);    
    
    if l_start then
      l_start := false;
      l_current_column := null;
    
      --Check for leading quote and set our flag
      l_quoted := l_current = l_quote;
      
      --We skip a leading quote character
      if l_quoted then goto loop_again; end if;
    end if;

    --Check to see if we are inside of a quote    
    if l_quoted then      

      --The current character is a quote - is it the end of our quote or does
      --it represent an escaped quote?
      if l_current = l_quote then

        --If the next character is a quote, this is an escaped quote.
        if l_next = l_quote then
        
          --Append the literal quote to our column
          append_current;
          
          --Advance the pointer to ignore the duplicated (escaped) quote
          l_position := l_position + 1;
          
        --If the next character is a separator, current is the end quote
        elsif l_next = p_separator then
          
          --Get out of the quote and loop again - we will hit the separator next loop
          l_quoted := false;
          goto loop_again;
        
        --Ending quote, no more columns
        elsif l_next is null then

          --Save our current value, and iterate (end loop)
          save_column;
          goto loop_again;          
          
        --Next character is not a quote
        else
          append_current;
        end if;
      else
      
        --The current character is not a quote - append it to our column value
        append_current;     
      end if;
      
    -- Not quoted
    else
    
      --Check if the current value is a separator, save or append as appropriate
      if l_current = p_separator then
        save_column;
      else
        append_current;
      end if;
    end if;
    
    --Check to see if we've used all our characters
    if l_next is null then
      save_column;
    end if;

    --The continue statement was not added to PL/SQL until 11g. Use GOTO in 9i.
    <<loop_again>> l_position := l_position + 1;
  end loop ;
  
  return l_returnvalue;
end csv_to_array;
 
 
function array_to_csv (p_values in t_str_array,
                       p_separator in varchar2 := g_default_separator) return varchar2
as
  l_value       varchar2(32767);
  l_returnvalue varchar2(32767);
begin
 
  /*
 
  Purpose:      convert array of values to CSV
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     31.03.2010  Created
  KJS     20.04.2011  Modified to allow quoted data, fixed a bug when 1st col was null
  */
  
  for i in p_values.first .. p_values.last loop
  
    --Double quotes must be escaped
    l_value := replace(p_values(i), '"', '""');
    
    --Values containing the separator, a double quote, or a new line must be quoted.
    if instr(l_value, p_separator) > 0 or instr(l_value, '"') > 0 or instr(l_value, chr(10)) > 0 then
      l_value := '"' || l_value || '"';
    end if;
    
    --Append our value to our return value
    if i = p_values.first then
      l_returnvalue := l_value;
    else
      l_returnvalue := l_returnvalue || p_separator || l_value;
    end if;
  end loop;
 
  return l_returnvalue;
 
end array_to_csv;


function get_array_value (p_values in t_str_array,
                          p_position in number,
                          p_column_name in varchar2 := null) return varchar2
as
  l_returnvalue varchar2(4000);
begin
 
  /*
 
  Purpose:      get value from array by position
 
  Remarks:     
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     31.03.2010  Created
 
  */
  
  if p_values.count >= p_position then
    l_returnvalue := p_values(p_position);
  else
    if p_column_name is not null then
      raise_application_error (-20000, 'Column number ' || p_position || ' does not exist. Expected column: ' || p_column_name);
    else
      l_returnvalue := null;
    end if;
  end if;
 
  return l_returnvalue;
 
end get_array_value;


function clob_to_csv (p_csv_clob in clob,
                      p_separator in varchar2 := g_default_separator,
                      p_skip_rows in number := 0) return t_csv_tab pipelined
as
  l_csv_clob               clob;
  l_line_separator         varchar2(2) := chr(13) || chr(10);
  l_last                   pls_integer;
  l_current                pls_integer;
  l_line                   varchar2(32000);
  l_line_number            pls_integer := 0;
  l_from_line              pls_integer := p_skip_rows + 1;
  l_line_array             t_str_array;
  l_row                    t_csv_line := t_csv_line (null, null,  -- line number, line raw
                                                     null, null, null, null, null, null, null, null, null, null,   -- lines 1-10
                                                     null, null, null, null, null, null, null, null, null, null);  -- lines 11-20
begin
 
  /*
 
  Purpose:      convert clob to CSV
 
  Remarks:      based on code from http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:1352202934074
                              and  http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:744825627183
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     31.03.2010  Created
  JLL     20.04.2015  Modified made an internal clob because || l_line_separator is very bad for performance
  */
  
  -- If the file has a DOS newline (cr+lf), use that
  -- If the file does not have a DOS newline, use a Unix newline (lf)
  if (nvl(dbms_lob.instr(p_csv_clob, l_line_separator, 1, 1),0) = 0) then
    l_line_separator := chr(10);
  end if;

  l_last := 1;
  l_csv_clob := p_csv_clob || l_line_separator;

  loop
  
    l_current := dbms_lob.instr (l_csv_clob , l_line_separator, l_last, 1);
    exit when (nvl(l_current,0) = 0);
    
    l_line_number := l_line_number + 1;
    
    if l_from_line <= l_line_number then
    
      l_line := dbms_lob.substr(l_csv_clob, l_current - l_last + 1, l_last);
      --l_line := replace(l_line, l_line_separator, '');
      l_line := replace(l_line, chr(10), '');
      l_line := replace(l_line, chr(13), '');

      l_line_array := csv_to_array (l_line, p_separator);

      l_row.line_number := l_line_number;
      l_row.line_raw := substr(l_line,1,4000);
      l_row.c001 := get_array_value (l_line_array, 1);
      l_row.c002 := get_array_value (l_line_array, 2);
      l_row.c003 := get_array_value (l_line_array, 3);
      l_row.c004 := get_array_value (l_line_array, 4);
      l_row.c005 := get_array_value (l_line_array, 5);
      l_row.c006 := get_array_value (l_line_array, 6);
      l_row.c007 := get_array_value (l_line_array, 7);
      l_row.c008 := get_array_value (l_line_array, 8);
      l_row.c009 := get_array_value (l_line_array, 9);
      l_row.c010 := get_array_value (l_line_array, 10);
      l_row.c011 := get_array_value (l_line_array, 11);
      l_row.c012 := get_array_value (l_line_array, 12);
      l_row.c013 := get_array_value (l_line_array, 13);
      l_row.c014 := get_array_value (l_line_array, 14);
      l_row.c015 := get_array_value (l_line_array, 15);
      l_row.c016 := get_array_value (l_line_array, 16);
      l_row.c017 := get_array_value (l_line_array, 17);
      l_row.c018 := get_array_value (l_line_array, 18);
      l_row.c019 := get_array_value (l_line_array, 19);
      l_row.c020 := get_array_value (l_line_array, 20);
      
      pipe row (l_row);
      
    end if;

    l_last := l_current + length (l_line_separator);

  end loop;

  return;
 
end clob_to_csv;


end csv_util_pkg;
/
 
