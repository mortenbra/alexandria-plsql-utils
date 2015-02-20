create or replace package body sql_builder_pkg
as

  /*

  Purpose:    Package helps construct SQL statements

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     01.01.2008  Created
  
  */


procedure set_from (p_query in out t_query,
                    p_name in varchar2)
as
begin

  /*

  Purpose:    set from list

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.02.2007  Created
  
  */
  
  p_query.f_from:=p_name;

end set_from; 


procedure add_select (p_query in out t_query,
                      p_name in varchar2)
as
begin

  /*

  Purpose:    add to select list

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.02.2007  Created
  
  */
  
  if p_query.f_select is null then
    p_query.f_select:=p_name;
  else
    p_query.f_select:=p_query.f_select || ', ' || p_name;
  end if;

end add_select; 


procedure add_from (p_query in out t_query,
                    p_name in varchar2)
as
begin

  /*

  Purpose:    add to from list

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.02.2007  Created
  
  */

  if p_query.f_from is null then
    p_query.f_from:=p_name;
  else
    p_query.f_from:=p_query.f_from || ', ' || p_name;
  end if;

end add_from; 


procedure add_where (p_query in out t_query,
                     p_name in varchar2)
as
begin

  /*

  Purpose:    add to where list

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.02.2007  Created
  
  */

  if p_query.f_where is null then
    p_query.f_where:='(' || p_name || ')';
  else
    p_query.f_where:=p_query.f_where || ' and (' || p_name || ')';
  end if;

end add_where; 


procedure add_group_by (p_query in out t_query,
                        p_name in varchar2)
as
begin

  /*

  Purpose:    add to group by list

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.02.2007  Created
  
  */

  if p_query.f_group_by is null then
    p_query.f_group_by:=p_name;
  else
    p_query.f_group_by:=p_query.f_group_by || ', ' || p_name;
  end if;

end add_group_by; 


procedure add_order_by (p_query in out t_query,
                        p_name in varchar2)
as
begin

  /*

  Purpose:    add to order by list

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.02.2007  Created
  
  */

  if p_query.f_order_by is null then
    p_query.f_order_by:=p_name;
  else
    p_query.f_order_by:=p_query.f_order_by || ', ' || p_name;
  end if;

end add_order_by;


function get_sql (p_query in t_query,
                  p_include_where in boolean := true,
                  p_include_group_by in boolean := true,
                  p_include_order_by in boolean := true) return varchar2
as
  l_returnvalue string_util_pkg.t_max_pl_varchar2;
begin

  /*

  Purpose:    get SQL text

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     08.02.2007  Created
  
  */
  
  l_returnvalue:='select ' || p_query.f_select || ' from ' || p_query.f_from;
  
  if (p_query.f_where is not null) and (p_include_where) then
    l_returnvalue:=l_returnvalue || ' where ' || p_query.f_where;
  end if;  
  
  if (p_query.f_group_by is not null) and (p_include_group_by) then
    l_returnvalue:=l_returnvalue || ' group by ' || p_query.f_group_by;
  end if;

  if (p_query.f_order_by is not null) and (p_include_order_by) then
    l_returnvalue:=l_returnvalue || ' order by ' || p_query.f_order_by;
  end if;

  return l_returnvalue;

end get_sql; 


end sql_builder_pkg;
/

