create or replace package body apex_util_pkg
as
 
  /*
 
  Purpose:      package provides general apex utilities
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.06.2008  Created
 
  */

function get_page_name (p_application_id in number,
                        p_page_id in number) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      purpose
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.06.2008  Created
 
  */
  
  begin
    select page_name
    into l_returnvalue 
    from apex_application_pages
    where application_id = p_application_id
    and page_id = p_page_id;
  exception
    when no_data_found then
      l_returnvalue := null;
  end;
 
  return l_returnvalue;
 
end get_page_name;


function get_item_name (p_page_id in number,
                        p_item_name in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get item name for page and item
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     10.01.2009  Created
 
  */
  
  l_returnvalue := upper('P' || p_page_id || '_' || p_item_name);
 
  return l_returnvalue;
 
end get_item_name;


function get_page_help_text (p_application_id in number,
                             p_page_id in number) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      purpose
 
  Remarks:
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     12.06.2008  Created
 
  */
  
  begin
    select help_text
    into l_returnvalue 
    from apex_application_pages
    where application_id = p_application_id
    and page_id = p_page_id;
  exception
    when no_data_found then
      l_returnvalue := null;
  end;
 
  return l_returnvalue;
 
end get_page_help_text;


function get_apex_url (p_page_id in varchar2,
                       p_request in varchar2 := null,
                       p_item_names in varchar2 := null,
                       p_item_values in varchar2 := null,
                       p_debug in varchar2 := null,
                       p_application_id in varchar2 := null,
                       p_session_id in number := null,
                       p_clear_cache in varchar2 := null) return varchar2
as
  l_returnvalue                  string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      return apex url
 
  Remarks:      url format: f?p=App:Page:Session:Request:Debug:ClearCache:itemNames:itemValues:PrinterFriendly
                App: Application Id
                Page: Page Id
                Session: Session ID
                Request: GET Request (button pressed)
                Debug: Whether show debug or not (YES/NO)
                ClearCache: Comma delimited string for page(s) for which cache is to be cleared
                itemNames: Used to set session state for page items, comma delimited
                itemValues: Partner to itemNames, actual session value
                PrinterFriendly: Set to YES if page is to be rendered printer friendly
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     26.03.2008  Created
  MBR     12.07.2011  Added clear cache parameter
 
  */
  
  l_returnvalue := 'f?p=' || nvl(p_application_id, v('APP_ID')) 
                          || ':'|| p_page_id 
                          || ':' || nvl(p_session_id, v('APP_SESSION'))
                          || ':' || p_request
                          || ':' || nvl(p_debug, 'NO')
                          || ':' || p_clear_cache
                          || ':' || p_item_names
                          || ':' || utl_url.escape(p_item_values)
                          || ':';
 
  return l_returnvalue;
 
end get_apex_url;


function get_apex_url_simple (p_page_id in varchar2,
                              p_item_name in varchar2 := null,
                              p_item_value in varchar2 := null,
                              p_request in varchar2 := null) return varchar2
as
  l_returnvalue                  string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      return apex url (simple syntax)
 
  Remarks:      assumes only one parameter, and prefixes the parameter name with page number
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     03.08.2010  Created
 
  */
  
  l_returnvalue := 'f?p=' || v('APP_ID') 
                          || ':'|| p_page_id 
                          || ':' || v('APP_SESSION')
                          || ':' || p_request
                          || ':' || 'NO'
                          || ':'
                          || ':' || case when p_item_name is not null then 'P' || p_page_id || '_' || p_item_name else null end
                          || ':' || utl_url.escape(p_item_value)
                          || ':';
 
  return l_returnvalue;
 
end get_apex_url_simple;


function get_apex_url_item_names (p_page_id in number,
                                  p_item_name_array in t_str_array) return varchar2
as
  l_returnvalue                  string_util_pkg.t_max_db_varchar2;
  l_str                          string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get item name
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  THH     28.05.2008  Created
 
  */
  
  for i in 1..p_item_name_array.count loop
  
    l_str := 'P' || p_page_id || '_' || p_item_name_array(i);
    l_returnvalue := string_util_pkg.add_item_to_list(l_str, l_returnvalue, ',');
  end loop;
 
  return l_returnvalue;
 
end get_apex_url_item_names;


function get_apex_url_item_values (p_item_value_array in t_str_array) return varchar2
as
  l_returnvalue                  string_util_pkg.t_max_db_varchar2;
  l_str                          string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get item values
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  THH     28.05.2008  Created
 
  */
  
  for i in 1..p_item_value_array.count loop

    l_str := p_item_value_array(i);
    l_returnvalue := string_util_pkg.add_item_to_list(l_str, l_returnvalue, ',');
    
  end loop;
 
  return l_returnvalue;                          

end get_apex_url_item_values;


function get_dynamic_lov_query (p_application_id in number,
                                p_lov_name in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*
 
  Purpose:      get query of dynamic lov
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  FDL     08.07.2008  Created
 
  */

  begin
  
    select list_of_values_query
    into l_returnvalue
    from apex_application_lovs
    where application_id = p_application_id
    and list_of_values_name = p_lov_name;
    
  exception
    when no_data_found then
      l_returnvalue := null;
  end;
  
  return l_returnvalue;
  
end get_dynamic_lov_query;


procedure set_apex_security_context (p_schema in varchar2)
as
begin

  /*

  Purpose:    set Apex security context

  Remarks:    to be able to run Apex APIs that require a context (security group ID) to be set

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     04.12.2009  Created

  */
  
  wwv_flow_api.set_security_group_id(apex_util.find_security_group_id(p_schema));


end set_apex_security_context;


procedure setup_apex_session_context (p_application_id in number,
                                      p_raise_exception_if_invalid in boolean := true)
as
begin

  /*
  
  Purpose:      setup Apex session context
  
  Remarks:      required before calling packages via the URL, outside the Apex framework
  
  Who      Date        Description
  ------  ----------  --------------------------------
  MBR     20.10.2009  Created
  MBR     22.12.2012  Added fix for breaking change in Apex 4.2, see http://code.google.com/p/plsql-utils/issues/detail?id=18
  MBR     22.12.2012  Added parameter to specify if no valid session should raise an exception
  
  */

  apex_application.g_flow_id := p_application_id;
  
  if apex_custom_auth.is_session_valid then

    apex_custom_auth.set_session_id (apex_custom_auth.get_session_id_from_cookie);
    apex_custom_auth.set_user (apex_custom_auth.get_username);
    wwv_flow_api.set_security_group_id (apex_custom_auth.get_security_group_id);
    
  else
    if p_raise_exception_if_invalid then
      raise_application_error (-20000, 'Session not valid.');
    end if;
  end if;

end setup_apex_session_context;

 
function get_str_value (p_str in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:    get string value

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.05.2010  Created

  */
  
  if p_str in (g_apex_null_str, g_apex_undefined_str) then
    l_returnvalue := null;
  else
    l_returnvalue := p_str;
  end if;
  
  return l_returnvalue;

end get_str_value;


function get_num_value (p_str in varchar2) return number
as
  l_returnvalue number;
begin

  /*

  Purpose:    get number value

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.05.2010  Created

  */
  
  if p_str in (g_apex_null_str, g_apex_undefined_str) then
    l_returnvalue := null;
  else
    -- assuming the NLS parameters are set correctly, we do NOT specify decimal or thousand separator
    l_returnvalue := string_util_pkg.str_to_num (p_str, null, null);
  end if;
  
  return l_returnvalue;

end get_num_value;


function get_date_value (p_str in varchar2) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    get date value

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.05.2010  Created

  */
  
  if p_str in (g_apex_null_str, g_apex_undefined_str) then
    l_returnvalue := null;
  else
    l_returnvalue := string_util_pkg.parse_date (p_str);
  end if;
  
  return l_returnvalue;

end get_date_value;


procedure set_item (p_page_id in varchar2,
                    p_item_name in varchar2,
                    p_value in varchar2) 
as
begin
 
  /*
 
  Purpose:      set Apex item value (string)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.11.2010  Created
 
  */
 
  apex_util.set_session_state ('P' || p_page_id || '_' || upper(p_item_name), p_value);
 
end set_item;
 

procedure set_date_item (p_page_id in varchar2,
                         p_item_name in varchar2,
                         p_value in date,
                         p_date_format in varchar2 := null) 
as
begin
 
  /*
 
  Purpose:      set Apex item value (date)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.11.2010  Created
 
  */
 
  apex_util.set_session_state ('P' || p_page_id || '_' || upper(p_item_name), to_char(p_value, nvl(p_date_format, date_util_pkg.g_date_fmt_date_hour_min)));
 
end set_date_item;

 
function get_item (p_page_id in varchar2,
                   p_item_name in varchar2,
                   p_max_length in number := null) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      get Apex item value (string)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.11.2010  Created
  MBR     01.12.2010  Added parameter for max length
 
  */
 
  l_returnvalue := get_str_value (apex_util.get_session_state ('P' || p_page_id || '_' || upper(p_item_name)));
  
  if p_max_length is not null then
    l_returnvalue := substr(l_returnvalue, 1, p_max_length);
  end if;

  return l_returnvalue;
 
end get_item;
 
 
function get_num_item (p_page_id in varchar2,
                       p_item_name in varchar2) return number
as
  l_returnvalue number;
begin
 
  /*
 
  Purpose:      get Apex item value (number)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.11.2010  Created
 
  */

  l_returnvalue := get_num_value (apex_util.get_session_state ('P' || p_page_id || '_' || upper(p_item_name)));
 
  return l_returnvalue;
 
end get_num_item;


function get_date_item (p_page_id in varchar2,
                        p_item_name in varchar2) return date
as
  l_returnvalue date;
begin
 
  /*
 
  Purpose:      get Apex item value (date)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.11.2010  Created
 
  */

  l_returnvalue := get_date_value (apex_util.get_session_state ('P' || p_page_id || '_' || upper(p_item_name)));
 
  return l_returnvalue;
 
end get_date_item;


procedure get_items (p_app_id in number,
                     p_page_id in number,
                     p_target in varchar2,
                     p_exclude_items in t_str_array := null) 
as

  cursor l_item_cursor
  is
  select item_name, substr(lower(item_name), length('p' || p_page_id || '_') +1 ) as field_name,
    display_as
  from apex_application_page_items
  where application_id = p_app_id
  and page_id = p_page_id
  and item_name not in (select upper(column_value) from table(p_exclude_items))
  and display_as not like '%does not save state%'
  order by item_name;

  l_sql                          string_util_pkg.t_max_pl_varchar2;
  l_cursor                       pls_integer;
  l_rows                         pls_integer;

begin
 
  /*
 
  Purpose:      get multiple item values from page into custom record type
 
  Remarks:      this procedure grabs all the values from a page, so we don't have to write code to retrieve each item separately
                since a PL/SQL function cannot return a dynamic type (%ROWTYPE and PL/SQL records are not supported by ANYDATA/ANYTYPE),
                  we must populate a global package variable as a workaround
                the global package variable (specified using the p_target parameter) must have fields matching the item names on the page
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     15.02.2011  Created
 
  */
 
  for l_rec in l_item_cursor loop
    l_sql := l_sql || '  ' || p_target || '.' || l_rec.field_name || ' := :b' || l_item_cursor%rowcount || ';' || chr(10);
  end loop;
  
  l_sql := 'begin' || chr(10) || l_sql || 'end;';
  
  --debug_pkg.printf('sql = %1', l_sql);
  
  begin
    l_cursor := dbms_sql.open_cursor;
    dbms_sql.parse (l_cursor, l_sql, dbms_sql.native);
    
    for l_rec in l_item_cursor loop
      if l_rec.display_as like '%Date Picker%' then
        dbms_sql.bind_variable (l_cursor, ':b' || l_item_cursor%rowcount, get_date_value(apex_util.get_session_state(l_rec.item_name)));
      else
        dbms_sql.bind_variable (l_cursor, ':b' || l_item_cursor%rowcount, get_str_value(apex_util.get_session_state(l_rec.item_name)));
      end if;
    end loop;
    
    l_rows := dbms_sql.execute (l_cursor);
    dbms_sql.close_cursor (l_cursor);
  exception
    when others then
      if dbms_sql.is_open (l_cursor) then
        dbms_sql.close_cursor (l_cursor);
      end if;
      raise;
  end;
 
end get_items;
 
 
procedure set_items (p_app_id in number,
                     p_page_id in number,
                     p_source in varchar2,
                     p_exclude_items in t_str_array := null) 
as

  cursor l_item_cursor
  is
  select item_name, substr(lower(item_name), length('p' || p_page_id || '_') +1 ) as field_name,
    display_as
  from apex_application_page_items
  where application_id = p_app_id
  and page_id = p_page_id
  and item_name not in (select upper(column_value) from table(p_exclude_items))
  and display_as not like '%does not save state%'
  order by item_name;

  l_sql                          string_util_pkg.t_max_pl_varchar2;

begin
 
  /*
 
  Purpose:      set multiple item values on page based on custom record type
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     15.02.2011  Created
 
  */
 
  for l_rec in l_item_cursor loop
    l_sql := l_sql || '  apex_util.set_session_state(''' || l_rec.item_name || ''', ' || p_source || '.' || l_rec.field_name || ');' || chr(10);
  end loop;
  
  l_sql := 'begin' || chr(10) || l_sql || 'end;';
  
  execute immediate l_sql;
 
end set_items;


function is_item_in_list (p_item in varchar2,
                          p_list in apex_application_global.vc_arr2) return boolean
as
  l_index       binary_integer;
  l_returnvalue boolean := false;
begin

  /*
 
  Purpose:      return true if specified item exists in list 
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     09.07.2011  Created
 
  */
  
  l_index := p_list.first;
  while (l_index is not null) loop
    if p_list(l_index) = p_item then
      l_returnvalue := true;
      exit;
    end if;
    l_index := p_list.next(l_index);
  end loop;

  return l_returnvalue; 

end is_item_in_list;


function get_apex_session_value (p_value_name in varchar2) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*
  
  Purpose:      get Apex session value
  
  Remarks:      if a package is called outside the Apex framework (but in a valid session -- see setup_apex_session_context),
                the session values are not available via apex_util.get_session_state or the V function, see http://forums.oracle.com/forums/thread.jspa?threadID=916301
                a workaround is to use the "do_substitutions" function, see http://apex-smb.blogspot.com/2009/07/apexapplicationdosubstitutions.html
  
  Who      Date        Description
  ------  ----------  --------------------------------
  MBR     26.01.2010  Created
  
  */

  l_returnvalue := apex_application.do_substitutions(chr(38) || upper(p_value_name) || '.');
  
  return l_returnvalue;

end get_apex_session_value;



end apex_util_pkg;
/
