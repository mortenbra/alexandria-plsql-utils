-- get URI by substituting values for placeholders

select uri_template_util_pkg.expand('/employees/{department}/{id}', t_str_array('Accounting', '1234'))
from dual


-- determine which URI template matches the URI
-- note: put most specific URI templates first 

select uri_template_util_pkg.match('/employees/Accounting/1234', t_str_array('/employees/{department}/list',
                                                                             '/employees/{department}/{id}',
                                                                             '/employees/{id}')
                                  ) as the_first_match
from dual


-- get name/value pairs from URI

declare
  l_values uri_template_util_pkg.t_dictionary;
  l_name   varchar2(255);  
begin
  debug_pkg.debug_on;
  l_values := uri_template_util_pkg.parse ('/employees/{department}/{id}', '/employees/Accounting/1234');
  l_name := l_values.first;
  while l_name is not null loop
    debug_pkg.printf('%1 = %2', l_name, l_values(l_name));
    l_name := l_values.next(l_name);
  end loop;
end;


-- combined example
-- in real-world usage, you would probably get the URI from an actual web request (for example through mod_plsql)

declare
  l_uri      varchar2(255);
  l_template varchar2(255);
  l_values   uri_template_util_pkg.t_dictionary;
  l_name     varchar2(255);  
begin
  debug_pkg.debug_on;

  l_uri := uri_template_util_pkg.expand('/employees/{department}/{id}', t_str_array('Accounting', '1234'));
  debug_pkg.printf('expanded uri = %1', l_uri);

  l_template := uri_template_util_pkg.match(l_uri, t_str_array('/employees/{department}/list',
                                                               '/employees/{department}/{id}',
                                                               '/employees/{id}'));
  debug_pkg.printf('the uri %1 matches the template %2', l_uri, l_template);

  l_values := uri_template_util_pkg.parse (l_template, l_uri);
  l_name := l_values.first;
  while l_name is not null loop
    debug_pkg.printf('%1 = %2', l_name, l_values(l_name));
    l_name := l_values.next(l_name);
  end loop;
end;

