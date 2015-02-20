create or replace package body employee_service
as

function get_employee_name (p_empno in number) return varchar2
as
  l_returnvalue emp.ename%type;
begin

  begin
    select ename
    into l_returnvalue
    from emp
    where empno = p_empno;
  exception
    when no_data_found then
      l_returnvalue := null;
  end;

  return l_returnvalue;

end get_employee_name;


function get_employee (p_empno in number) return emp%rowtype
as
  l_returnvalue emp%rowtype;
begin

  begin
    select *
    into l_returnvalue
    from emp
    where empno = p_empno;
  exception
    when no_data_found then
      l_returnvalue := null;
  end;

  return l_returnvalue;

end get_employee;


function get_employees (p_search_filter in varchar2) return clob
as
  l_context     dbms_xmlgen.ctxhandle;
  l_returnvalue clob;
begin

  -- there are many ways to generate XML in Oracle, this is one of them...

  l_context := dbms_xmlgen.newcontext('select * from emp where lower(ename) like :p_filter_str order by empno');

  -- let's make Tom Kyte happy :-)
  dbms_xmlgen.setbindvalue (l_context, 'p_filter_str', lower(p_search_filter) || '%');

  l_returnvalue := dbms_xmlgen.getxml (l_context);
  
  dbms_xmlgen.closecontext (l_context);

  return l_returnvalue;

end get_employees;


procedure some_procedure (p_param1 in varchar2)
as
begin
  -- just to show that procedures will not be exposed in the WSDL
  null;
end some_procedure;


function new_employee (p_ename in varchar2) return number
as
begin

  -- this would normally insert into a table and return the new primary key value

  return 666;

end new_employee;


function get_employees_by_date (p_from_date in date,
                                p_to_date in date) return clob
as
begin

  -- show/test that functions can accept date parameters

  return 'You searched for employees between ' || to_char(p_from_date, 'dd.mm.yyyy') || ' and ' || to_char(p_to_date, 'dd.mm.yyyy');

end get_employees_by_date;


function no_input_parameters return varchar2
as
begin
  return 'Hello There';
end no_input_parameters;


function get_first_hire_date return date
as
  l_returnvalue date;
begin

  select min(hiredate)
  into l_returnvalue
  from emp;

  return l_returnvalue;

end get_first_hire_date;

end employee_service;
/

