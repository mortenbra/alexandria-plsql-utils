create or replace package body rss_util_pkg
as

  /*

  Purpose:    Package handles web feeds (RSS/Atom)

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */
  
  g_date_format_rss              constant varchar2(50) := 'Dy, DD Mon YYYY HH24:MI:SS "+0000"';
  g_date_format_rdf              constant varchar2(50) := 'YYYY-MM-DD"T"HH24:MI:SS".000Z"';
  g_date_format_atom             constant varchar2(50) := 'YYYY-MM-DD"T"HH24:MI:SS".000Z"';
  
  g_namespace_rdf                constant varchar2(255) := 'xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://purl.org/rss/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/"';
  g_namespace_atom               constant varchar2(255) := 'xmlns="http://www.w3.org/2005/Atom"';

function fmt_date (p_date in date,
                   p_format in varchar2 := null) return varchar2
as
  l_returnvalue varchar2(100);
begin

  /*

  Purpose:    format date for feed

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */
  
  if p_format = g_format_rss then
    l_returnvalue := to_char(p_date, g_date_format_rss,'NLS_DATE_LANGUAGE = ENGLISH');
  elsif p_format = g_format_rdf then
    l_returnvalue := to_char(p_date, g_date_format_rdf);
  elsif p_format = g_format_atom then
    l_returnvalue := to_char(p_date, g_date_format_atom);
  end if;
  
  return l_returnvalue;

end fmt_date;


function get_date (p_date_str in varchar2,
                   p_format in varchar2 := null) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    get date for specific feed format

  Remarks:    for RSS, we ignore the timezone part
              for RDF/Atom, the fractional seconds part is optional, we ignore it always
              

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created
  MBR     21.04.2012  Fixed: l_returnvalue was defined as varchar2 instead of date

  */
  
  begin
    if p_format = g_format_rss then
      --l_returnvalue := to_date(p_date_str, g_date_format_rss);
      l_returnvalue := to_date(substr(p_date_str,1,26), 'Dy, DD Mon YYYY HH24:MI:SS','NLS_DATE_LANGUAGE = ENGLISH');
    elsif p_format = g_format_rdf then
      --l_returnvalue := to_date(p_date_str, g_date_format_rdf);
      l_returnvalue := to_date(substr(p_date_str,1,19), 'YYYY-MM-DD"T"HH24:MI:SS');
    elsif p_format = g_format_atom then
      --l_returnvalue := to_date(p_date_str, g_date_format_atom);
      l_returnvalue := to_date(substr(p_date_str,1,19), 'YYYY-MM-DD"T"HH24:MI:SS');
    end if;
  exception
    when others then
      l_returnvalue := null;
  end;
  
  return l_returnvalue;

end get_date;


function ref_cursor_to_feed (p_ref_cursor in sys_refcursor,
                             p_feed_title in varchar2,
                             p_feed_description in varchar2 := null,
                             p_feed_link in varchar2 := null,
                             p_feed_date in date := null,
                             p_format in varchar2 := null) return clob
as
  l_format                       varchar2(10) := nvl(p_format, g_format_rss);
  l_items                        t_feed_item_list;
  l_returnvalue                  clob;
begin

  /*

  Purpose:    ref cursor to rss

  Remarks:    the ref cursor (query) used must match the definition of the t_feed_item type (column order and data types),
              although the actual column names are irrelevant

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created
  MBR     10.10.2011  Added escaping of special characters in title/description

  */
  
  fetch p_ref_cursor
  bulk collect
  into l_items;
  
  close p_ref_cursor;
  
  if l_format = g_format_rss then
  
    l_returnvalue := '<?xml version="1.0" encoding="UTF-8" ?>
    <rss version="2.0">
    <channel>
      <title>' || htf.escape_sc(p_feed_title) || '</title>
      <description>' || htf.escape_sc(p_feed_description) || '</description>
      <link>' || p_feed_link || '</link>
      <lastBuildDate>' || fmt_date(nvl(p_feed_date, sysdate), l_format) || '</lastBuildDate>
      <pubDate>' || fmt_date(sysdate, p_format) || '</pubDate>';
   
    for i in 1 .. l_items.count loop
    
      l_returnvalue := l_returnvalue || '
      <item>
        <title>' || htf.escape_sc(l_items(i).item_title) || '</title>
        <description>' || htf.escape_sc(l_items(i).item_description) || '</description>
        <link>' || l_items(i).item_link || '</link>
        <guid>' || l_items(i).item_guid || '</guid>
        <pubDate>' || fmt_date (l_items(i).item_date, l_format) || '</pubDate>
      </item>';
      
    end loop;
    
    l_returnvalue := l_returnvalue || '</channel></rss>';

  elsif l_format = g_format_rdf then

    l_returnvalue := '<?xml version="1.0" encoding="UTF-8" ?>
    <rdf:RDF ' || g_namespace_rdf || '>
    <channel>
      <title>' || htf.escape_sc(p_feed_title) || '</title>
      <description>' || htf.escape_sc(p_feed_description) || '</description>
      <link>' || p_feed_link || '</link>
      <dc:date>' || fmt_date(nvl(p_feed_date, sysdate), l_format) || '</dc:date>
      <items>
        <rdf:Seq>';
   
    for i in 1 .. l_items.count loop
      l_returnvalue := l_returnvalue || '
      <rdf:li resource="' || l_items(i).item_guid || '" />';
    end loop;
    
    l_returnvalue := l_returnvalue || '</rdf:Seq></items></channel>';
  
    for i in 1 .. l_items.count loop
    
      l_returnvalue := l_returnvalue || '
      <item rdf:about="' || l_items(i).item_guid || '">
        <title>' || htf.escape_sc(l_items(i).item_title) || '</title>
        <description>' || htf.escape_sc(l_items(i).item_description) || '</description>
        <link>' || l_items(i).item_link || '</link>
        <dc:date>' || fmt_date (l_items(i).item_date, l_format) || '</dc:date>
      </item>';
      
    end loop;
    
    l_returnvalue := l_returnvalue || '</rdf:RDF>';
    
  elsif l_format = g_format_atom then
  
    l_returnvalue := '<?xml version="1.0" encoding="UTF-8" ?>
    <feed ' || g_namespace_atom || '>
    <title>' || htf.escape_sc(p_feed_title) || '</title>
    <subtitle>' || htf.escape_sc(p_feed_description) || '</subtitle>
    <link href="' || p_feed_link || '" rel="self" />
    <link href="' || p_feed_link || '" />
    <id>' || to_char(sysdate, 'yyyymmddhh24miss') || '</id>
    <updated>' || fmt_date(nvl(p_feed_date, sysdate), l_format) || '</updated>';
 
    for i in 1 .. l_items.count loop
    
      l_returnvalue := l_returnvalue || '
      <entry>
        <title>' || htf.escape_sc(l_items(i).item_title) || '</title>
        <link href="' || l_items(i).item_link || '" />
        <link rel="alternate" type="text/html" href="' || l_items(i).item_link || '"/>
        <link rel="edit" href="' || l_items(i).item_link || '"/>
        <id>' || l_items(i).item_guid || '</id>
        <updated>' || fmt_date (l_items(i).item_date, l_format) || '</updated>
        <summary>' || htf.escape_sc(l_items(i).item_description) || '</summary>
      </entry>';
  
    end loop;
 
    l_returnvalue := l_returnvalue || '</feed>';

  end if;
  
  return l_returnvalue;

end ref_cursor_to_feed;


function get_format (p_xml in xmltype) return varchar2
as
  l_returnvalue varchar2(10);
begin

  /*

  Purpose:    attempt to autodetect format based on XML

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */
  
  begin
  
    if p_xml.existsnode ('/rdf:RDF', g_namespace_rdf) = 1 then
      l_returnvalue := g_format_rdf;
    elsif p_xml.existsnode ('/feed', g_namespace_atom) = 1 then
      l_returnvalue := g_format_atom;
    else
      l_returnvalue := g_format_rss;
    end if;  
  
  exception
    when others then
      l_returnvalue := g_format_rss;
  end;
  
  return l_returnvalue;

end get_format;


function rss_to_list (p_feed in clob,
                      p_format in varchar2 := null) return t_feed_item_list
as
  l_returnvalue                  t_feed_item_list;
  l_xml                          xmltype;
  l_count                        pls_integer := 0;
  l_format                       varchar2(10);
begin

  /*

  Purpose:    rss feed to list

  Remarks:    problem with 10g, extractValue and node text over 4k (typically in description field), see http://forums.oracle.com/forums/thread.jspa?threadID=353436

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */

  l_xml := xmltype (p_feed);
  
  l_format := coalesce (p_format, get_format (l_xml));
  
  if l_format = g_format_rss then

    for l_rec in (
      select extractValue(value(t), '*/guid') as item_guid,
        extractValue(value(t), '*/title') as item_title,
        extractValue(value(t), '*/description') as item_description,
        extractValue(value(t), '*/link') as item_link,
        extractValue(value(t), '*/pubDate') as item_date
      from table(xmlsequence(l_xml.extract('//rss/channel/item'))) t
      ) loop
      l_count := l_count + 1;
      l_returnvalue(l_count).item_guid := l_rec.item_guid;
      l_returnvalue(l_count).item_title := l_rec.item_title;
      l_returnvalue(l_count).item_description := l_rec.item_description;
      l_returnvalue(l_count).item_link := l_rec.item_link;
      l_returnvalue(l_count).item_date := get_date (l_rec.item_date, l_format);
    end loop;

  elsif l_format = g_format_rdf then

    for l_rec in (
      select extractValue(value(t), '*/@rdf:about', g_namespace_rdf) as item_guid,
        extractValue(value(t), '*/title', g_namespace_rdf) as item_title,
        extractValue(value(t), '*/description', g_namespace_rdf) as item_description,
        extractValue(value(t), '*/link', g_namespace_rdf) as item_link,
        extractValue(value(t), '*/dc:date', g_namespace_rdf) as item_date
      from table(xmlsequence(l_xml.extract('//rdf:RDF/item', g_namespace_rdf))) t
      ) loop
      l_count := l_count + 1;
      l_returnvalue(l_count).item_guid := l_rec.item_guid;
      l_returnvalue(l_count).item_title := l_rec.item_title;
      l_returnvalue(l_count).item_description := l_rec.item_description;
      l_returnvalue(l_count).item_link := l_rec.item_link;
      l_returnvalue(l_count).item_date := get_date (l_rec.item_date, l_format);
    end loop;

  elsif l_format = g_format_atom then
  
    for l_rec in (
      select extractValue(value(t), '*/id', g_namespace_atom) as item_guid,
        extractValue(value(t), '*/title', g_namespace_atom) as item_title,
        extractValue(value(t), '*/summary', g_namespace_atom) as item_description,
        extractValue(value(t), '*/link[1]/@href', g_namespace_atom) as item_link,
        extractValue(value(t), '*/updated', g_namespace_atom) as item_date
      from table(xmlsequence(l_xml.extract('//feed/entry', g_namespace_atom))) t
      ) loop
      l_count := l_count + 1;
      l_returnvalue(l_count).item_guid := l_rec.item_guid;
      l_returnvalue(l_count).item_title := l_rec.item_title;
      l_returnvalue(l_count).item_description := l_rec.item_description;
      l_returnvalue(l_count).item_link := l_rec.item_link;
      l_returnvalue(l_count).item_date := get_date (l_rec.item_date, l_format);
    end loop;
    
  end if;
  
  return l_returnvalue;

end rss_to_list;


function rss_to_table (p_feed in clob,
                       p_format in varchar2 := null) return t_feed_item_tab pipelined
as
  l_items                        t_feed_item_list;
begin

  /*

  Purpose:    rss feed to table rows

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     22.01.2011  Created

  */
  
  l_items := rss_to_list (p_feed, p_format);
  
  for i in 1 .. l_items.count loop
    pipe row (l_items(i));
  end loop;

  return;

end rss_to_table;


end rss_util_pkg;
/

