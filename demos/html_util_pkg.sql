
-- add clickable links to text with URLs in it

select html_util_pkg.add_hyperlinks('hey check out http://www.oracle.com and http://www.microsoft.com', 'my_link_css_class')
from dual

