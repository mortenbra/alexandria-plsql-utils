-- generate RSS feed from ref cursor (supports different output formats: rss/rdf/atom)

declare
  l_clob clob;
  l_cursor sys_refcursor;
begin
  debug_pkg.debug_on;
  open l_cursor for select empno, ename, job as descr, 'http://127.0.0.1:8080/devtest/demo.employee?p_id=' || empno as link, hiredate from emp order by ename;
  l_clob := rss_util_pkg.ref_cursor_to_feed (l_cursor, 'my feed from pl/sql', p_format => rss_util_pkg.g_format_rss);
  debug_pkg.print(substr(l_clob, 1, 32000));
end;


-- parse RSS feed into rows
-- NOTE: feed format will be autodetected if you leave out the format parameter

select *
from table(rss_util_pkg.rss_to_table(httpuritype('http://127.0.0.1:8080/devtest/demo.employee_rss').getclob(), 'rss'))

select *
from table(rss_util_pkg.rss_to_table(httpuritype('http://www.dagbladet.no/rss/forsida/').getclob(), 'rss'))

-- RDF variety

select *
from table(rss_util_pkg.rss_to_table(httpuritype('http://www.aftenposten.no/eksport/rss-1_0/').getclob(), 'rdf'))

select *
from table(rss_util_pkg.rss_to_table(httpuritype('http://rss.slashdot.org/Slashdot/slashdot').getclob(), 'rdf'))

-- Atom variety

select *
from table(rss_util_pkg.rss_to_table(httpuritype('http://stackoverflow.com/feeds').getclob(), 'atom'))


-- process feed items via PL/SQL

declare
  l_items rss_util_pkg.t_feed_item_list;
begin
  debug_pkg.debug_on;
  l_items := rss_util_pkg.rss_to_list(httpuritype('http://stackoverflow.com/feeds').getclob());
  for i in 1 .. l_items.count loop
    debug_pkg.printf('item %1, title = %2', i, l_items(i).item_title);
  end loop;
end;

