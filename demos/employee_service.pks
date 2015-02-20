create or replace package employee_service
as

  -- test package to showcase "PL/SQL SOAP Server" features (see soap_server_pkg)

  function get_employee_name (p_empno in number) return varchar2;
  
  function get_employee (p_empno in number) return emp%rowtype;

  function get_employees (p_search_filter in varchar2) return clob;

  procedure some_procedure (p_param1 in varchar2);

  function new_employee (p_ename in varchar2) return number;

  function get_employees_by_date (p_from_date in date,
                                  p_to_date in date) return clob;

  function no_input_parameters return varchar2;
  
  function get_first_hire_date return date;

end employee_service;
/


