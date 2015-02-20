create or replace package sql_builder_pkg
as

  /*

  Purpose:    Package helps construct SQL statements

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     01.01.2008  Created
  
  */


  type t_query is record (
    f_select     string_util_pkg.t_max_pl_varchar2,
    f_from       string_util_pkg.t_max_pl_varchar2,
    f_where      string_util_pkg.t_max_pl_varchar2,
    f_group_by   string_util_pkg.t_max_pl_varchar2,
    f_order_by   string_util_pkg.t_max_pl_varchar2
  );
  
  -- set from list
  procedure set_from (p_query in out t_query,
                      p_name in varchar2);
  
  -- add to select list
  procedure add_select (p_query in out t_query,
                        p_name in varchar2); 
  
  -- add to from list
  procedure add_from (p_query in out t_query,
                      p_name in varchar2); 

  -- add to where list
  procedure add_where (p_query in out t_query,
                       p_name in varchar2); 

  -- add to group by list
  procedure add_group_by (p_query in out t_query,
                          p_name in varchar2); 

  -- add to order by list
  procedure add_order_by (p_query in out t_query,
                          p_name in varchar2); 

  -- get SQL text
  function get_sql (p_query in t_query,
                    p_include_where in boolean := true,
                    p_include_group_by in boolean := true,
                    p_include_order_by in boolean := true) return varchar2; 

end sql_builder_pkg;
/

