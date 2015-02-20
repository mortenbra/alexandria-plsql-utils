create or replace package rss_util_pkg
as

  /*

  Purpose:    Package handles web feeds (RSS/Atom)

  Remarks:    see http://www.rssboard.org/rss-specification

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */
  
  -- this is a simplification
  -- see http://en.wikipedia.org/wiki/RSS#Variants
  -- see http://www.tutorialspoint.com/rss/rss-quick-guide.htm
  g_format_rss                   constant varchar2(10) := 'rss';
  g_format_rdf                   constant varchar2(10) := 'rdf';
  g_format_atom                  constant varchar2(10) := 'atom';

  type t_feed_item is record (
    item_guid varchar2(255),
    item_title varchar2(4000),
    item_description varchar2(4000),
    item_link varchar2(4000),
    item_date date
  );

  type t_feed_item_list is table of t_feed_item index by binary_integer;
  
  type t_feed_item_tab is table of t_feed_item;

  -- ref cursor to rss
  function ref_cursor_to_feed (p_ref_cursor in sys_refcursor,
                               p_feed_title in varchar2,
                               p_feed_description in varchar2 := null,
                               p_feed_link in varchar2 := null,
                               p_feed_date in date := null,
                               p_format in varchar2 := null) return clob;
                               
  -- rss feed to list
  function rss_to_list (p_feed in clob,
                        p_format in varchar2 := null) return t_feed_item_list;

  -- rss feed to table rows
  function rss_to_table (p_feed in clob,
                         p_format in varchar2 := null) return t_feed_item_tab pipelined;

end rss_util_pkg;
/

