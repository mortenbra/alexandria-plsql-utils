create or replace package body debug_pkg
as

  /*

  Purpose:    The package handles debug information

  Remarks:    Debugging is turned OFF by default

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  
  m_debugging                     boolean := false;


procedure debug_off
as
begin

  /*

  Purpose:    Turn off debugging

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  m_debugging:=false;

end debug_off;


procedure debug_on
as
begin

  /*

  Purpose:    Turn on debugging

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  m_debugging:=true;

end debug_on;


procedure print (p_msg in varchar2)
as
  l_text varchar2(32000);
begin

  /*

  Purpose:    Print debug information

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  if (apex_application.g_debug) then

    apex_application.debug (p_msg);

  elsif (m_debugging) then

    l_text:=to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss') || ': ' || nvl(p_msg, '(null)');
    
    loop
      exit when l_text is null;
      dbms_output.put_line(substr(l_text,1,250));
      l_text:=substr(l_text, 251);
    end loop;

  end if;

end print;


procedure print (p_msg in varchar2,
                 p_value in varchar2)
as
begin

  /*

  Purpose:    Print debug information (name/value pair)

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  print (p_msg || ': ' || p_value);
  
end print;


procedure print (p_msg in varchar2,
                 p_value in number)
as
begin

  /*

  Purpose:    Print debug information (numeric value)

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  print (p_msg || ': ' || nvl(to_char(p_value), '(null)'));
  
end print;


procedure print (p_msg in varchar2,
                 p_value in date)
as
begin

  /*

  Purpose:    Print debug information (date value)

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  print (p_msg || ': ' || nvl(to_char(p_value, 'dd.mm.yyyy hh24:mi:ss'), '(null)'));
  
end print;


procedure print (p_msg in varchar2,
                 p_value in boolean)
as
  l_str varchar2(20);
begin

  /*

  Purpose:    Print debug information (boolean value)

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     23.02.2009  Created
  
  */
  
  if p_value is null then
    l_str := '(null)';
  elsif p_value = true then
    l_str := 'true';
  else
    l_str := 'false';
  end if;

  print (p_msg || ': ' || l_str);
  
end print;


procedure print (p_refcursor in sys_refcursor,
                 p_null_handling in number := 0)
as
  l_xml      xmltype;
  l_context  dbms_xmlgen.ctxhandle;
  l_clob     clob;

  l_null_self_argument_exc exception;
  pragma exception_init (l_null_self_argument_exc, -30625);
  
begin

  /*

  Purpose:    print debug information (ref cursor)

  Remarks:    outputs weakly typed cursor as XML

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     27.09.2006  Created
  
  */

  -- get a handle on the ref cursor
  l_context:=dbms_xmlgen.newcontext (p_refcursor);

  /*
  
  # DROP_NULLS CONSTANT NUMBER:= 0; (Default) Leaves out the tag for NULL elements.
  # NULL_ATTR CONSTANT NUMBER:= 1; Sets xsi:nil="true".
  # EMPTY_TAG CONSTANT NUMBER:= 2; Sets, for example, <foo/>.
  
  */

  -- how to handle null values
  dbms_xmlgen.setnullhandling (l_context, p_null_handling);

  -- create XML from ref cursor
  l_xml:=dbms_xmlgen.getxmltype (l_context, dbms_xmlgen.none);

  print('Number of rows in ref cursor', dbms_xmlgen.getnumrowsprocessed (l_context));
  
  begin
    l_clob:=l_xml.getclobval();
    if length(l_clob) > 32000 then
      print('Size of XML document (anything over 32K will be truncated)', length(l_clob));
    end if;
    print(p_msg => substr(l_clob,1,32000));
  exception
    when l_null_self_argument_exc then
       print('Empty dataset.');
  end;

end print;


procedure print (p_xml in xmltype)
as
  l_clob     clob;
begin

  /*

  Purpose:    print debug information (XMLType)

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     18.01.2011  Created
  
  */
  
  begin
    l_clob:=p_xml.getclobval();
    if length(l_clob) > 32000 then
      print('Size of XML document (anything over 32K will be truncated)', length(l_clob));
    end if;
    print(p_msg => substr(l_clob,1,32000));
  exception
    when others then
       print(sqlerrm);
  end;

end print;


procedure print (p_clob in clob)
as
begin

  /*

  Purpose:    print debug information (clob)

  Remarks:     

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.03.2011  Created
  
  */
  
  begin
    if length(p_clob) > 4000 then
      print('Size of CLOB (anything over 4K will be truncated)', length(p_clob));
    end if;
    print(p_msg => substr(p_clob,1,4000));
  exception
    when others then
       print(sqlerrm);
  end;

end print;


procedure printf (p_msg in varchar2,
                  p_value1 in varchar2 := null,
                  p_value2 in varchar2 := null,
                  p_value3 in varchar2 := null,
                  p_value4 in varchar2 := null,
                  p_value5 in varchar2 := null,
                  p_value6 in varchar2 := null,
                  p_value7 in varchar2 := null,
                  p_value8 in varchar2 := null)
as
  l_text varchar2(32000);
begin

  /*

  Purpose:    Print debug information (multiple values)

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  if (m_debugging or apex_application.g_debug) then
  
    l_text:=p_msg;
    
    l_text:=replace(l_text, '%1', nvl (p_value1, '(blank)'));
    l_text:=replace(l_text, '%2', nvl (p_value2, '(blank)'));
    l_text:=replace(l_text, '%3', nvl (p_value3, '(blank)'));
    l_text:=replace(l_text, '%4', nvl (p_value4, '(blank)'));
    l_text:=replace(l_text, '%5', nvl (p_value5, '(blank)'));
    l_text:=replace(l_text, '%6', nvl (p_value6, '(blank)'));
    l_text:=replace(l_text, '%7', nvl (p_value7, '(blank)'));
    l_text:=replace(l_text, '%8', nvl (p_value8, '(blank)'));

    print (l_text);
  
  end if;

end printf;


function get_fdate(p_date in date) return varchar2
as
begin

  /*

  Purpose:    Get date string in debug format

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created
  
  */

  return nvl(to_char(p_date, 'dd.mm.yyyy hh24:mi:ss'), '(null)');

end get_fdate;


procedure set_info (p_action in varchar2,
                    p_module in varchar2 := null)
as
begin

  /*

  Purpose:    set session info (will be available in v$session)

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.09.2006  Created
  
  */
  
  if p_module is not null then
    dbms_application_info.set_module (p_module, p_action);
  else
    dbms_application_info.set_action (p_action);
  end if;

end set_info;


procedure clear_info
as
begin

  /*

  Purpose:    clear session info

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.09.2006  Created
  
  */
  
  dbms_application_info.set_module (null, null);
  
end clear_info;


end debug_pkg;
/

