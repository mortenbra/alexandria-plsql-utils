
-- a simple API to build an SQL string

declare
  l_my_query sql_builder_pkg.t_query;
  l_sql varchar2(32000);
begin
  debug_pkg.debug_on;
  sql_builder_pkg.add_select (l_my_query, 'ename');
  sql_builder_pkg.add_select (l_my_query, 'sal');
  sql_builder_pkg.add_select (l_my_query, 'deptno');
  sql_builder_pkg.add_from (l_my_query, 'emp');
  sql_builder_pkg.add_where (l_my_query, 'ename = :p_ename');
  sql_builder_pkg.add_where (l_my_query, 'sal > :p_sal');
  l_sql := sql_builder_pkg.get_sql (l_my_query);
  debug_pkg.printf(l_sql);
end;
