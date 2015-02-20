create or replace package body soap_server_pkg
as

  /*

  Purpose:   Package implements a SOAP server in PL/SQL

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  -- start customizable section
  g_debug_mode_enabled           constant boolean := true;                        -- set to false for production use
  g_schema_name                  constant varchar2(255) := 'devtest';             -- change to schema where package is installed
  g_package_name                 constant varchar2(255) := 'soap_server_pkg';     -- leave as-is unless package name is changed
  g_target_namespace             constant varchar2(255) := 'http://tempuri.org';  -- change to your-organization.com/services
  g_protocol                     constant varchar2(255) := 'http';                -- change to https if using SSL
  -- end customizable section

  g_xml_date_format              constant varchar2(255) := 'YYYY-MM-DD"T"HH24:MI:SS".000"';
  g_application_error_code       constant number := -20000;

  type t_program is record (
    program_name user_arguments.object_name%type
  );
  
  type t_program_tab is table of t_program index by binary_integer;

  type t_argument is record (
    argument_name user_arguments.argument_name%type,
    position      user_arguments.position%type,
    data_type     user_arguments.data_type%type
  );
  
  type t_argument_tab is table of t_argument index by binary_integer;
  
  type t_request_param is record (
    param_name           varchar2(30),
    data_type            varchar2(30),
    param_value_string   varchar2(32000),
    param_value_date     date,
    param_value_number   number
    
  );
  
  type t_request_param_tab is table of t_request_param index by binary_integer;
  
  type t_request is record (
    package_name        varchar2(30),
    program_name        varchar2(30),
    operation_name      varchar2(30),
    params              t_request_param_tab
  );
  
  type t_response is record (
    operation_name      varchar2(30),
    result_text         varchar2(32000),
    result_clob         clob
  );


procedure raise_error (p_error_text in varchar2)
as
begin

  /*

  Purpose:   Raise error

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     29.12.2010  Created
  
  */

  raise_application_error (g_application_error_code, p_error_text);
  
end raise_error;


function is_whitelisted (p_package_name in varchar2,
                         p_program_name in varchar2 := null) return boolean
as
  l_returnvalue boolean := false;
begin

  /*

  Purpose:   Check if package/function should be exposed as SOAP service

  Remarks:   *** IMPORTANT *** : make sure you understand the security implications of modifying this function
             This package executes dynamic SQL, and unless you are careful with this whitelist, you may expose your database to SQL injection attacks!

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  if lower(p_package_name) in ('employee_service') then
    l_returnvalue := true;
  end if;
  
  return l_returnvalue;

end is_whitelisted;


function get_soap_data_type (p_data_type in varchar2) return varchar2
as
  l_returnvalue varchar2(30);
begin

  /*

  Purpose:   Get SOAP data type from Oracle data type

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  if p_data_type in ('CHAR', 'VARCHAR', 'VARCHAR2', 'CLOB') then
    l_returnvalue := 'string';
  elsif p_data_type in ('NUMBER') then
    l_returnvalue := 'double';
  elsif p_data_type in ('INTEGER') then
    l_returnvalue := 'int';
  elsif p_data_type in ('DATE') then
    l_returnvalue := 'dateTime';
  else
    l_returnvalue := 'string';
  end if;
  
  return l_returnvalue;

end get_soap_data_type;


function pretty_str (p_str in varchar2) return varchar2
as
  l_returnvalue varchar2(2000);
begin

  /*

  Purpose:   Convert string to "pretty" string

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  l_returnvalue := replace(initcap(p_str), '_', '');
  
  return l_returnvalue;

end pretty_str;


function get_programs (p_package_name in varchar2) return t_program_tab
as
  l_returnvalue t_program_tab;
  
  cursor l_program_cursor
  is
  select distinct object_name
  from user_arguments
  where package_name = upper(p_package_name)
  and position = 0 -- functions only
  order by 1;
  
begin

  /*

  Purpose:   Get programs in package

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */

  open l_program_cursor;
  
  fetch l_program_cursor
  bulk collect
  into l_returnvalue;
  
  close l_program_cursor;

  return l_returnvalue;

end get_programs;


function get_arguments (p_package_name in varchar2,
                        p_object_name in varchar2) return t_argument_tab
as
  l_returnvalue t_argument_tab;
  
  cursor l_parameter_cursor
  is
  select argument_name, position, data_type
  from user_arguments
  where package_name = upper(p_package_name)
  and object_name = upper(p_object_name)
  and argument_name is not null
  and in_out = 'IN'
  order by overload, sequence;
  
begin

  /*

  Purpose:   Get program arguments

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */

  open l_parameter_cursor;
  
  fetch l_parameter_cursor
  bulk collect
  into l_returnvalue;
  
  close l_parameter_cursor;

  return l_returnvalue;

end get_arguments;


procedure wsdl (s in varchar2)
as
  l_programs                     t_program_tab;
  l_arguments                    t_argument_tab;
  
  l_package_name                 varchar2(30);
  l_service_name                 varchar2(30);
  l_pretty_program_name          varchar2(30);

begin
  
  /*

  Purpose:   Generate WSDL for service (package)

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  l_package_name := upper (dbms_assert.sql_object_name(s));

  if not is_whitelisted (l_package_name) then
    raise_error ('Invalid service specified.');
  end if;
  
  l_service_name := pretty_str (l_package_name);
  
  l_programs := get_programs (l_package_name);

  owa_util.mime_header('text/xml; charset=utf-8;', true);
  
  htp.p('<?xml version="1.0" encoding="utf-8"?>');
  htp.p('<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="' || g_target_namespace || '" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="' || g_target_namespace || '" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" >');
  
  --------
  -- types
  --------
  
  htp.p('<wsdl:types>');
  htp.p('<s:schema elementFormDefault="qualified" targetNamespace="' || g_target_namespace || '">');

  for i in l_programs.first .. l_programs.last loop

    l_pretty_program_name := pretty_str (l_programs(i).program_name);

    htp.p('<s:element name="' || l_pretty_program_name || '">');
    htp.p('<s:complexType>');
    htp.p('<s:sequence>');
    
    l_arguments := get_arguments (l_package_name, l_programs(i).program_name);
    
    if l_arguments.count > 0 then
      for j in l_arguments.first .. l_arguments.last loop
        htp.p('<s:element minOccurs="1" maxOccurs="1" name="' || lower(l_arguments(j).argument_name) || '" type="s:' || get_soap_data_type (l_arguments(j).data_type) || '" />');
      end loop;
    end if;
    
    htp.p('</s:sequence>');
    htp.p('</s:complexType>');
    htp.p('</s:element>');

    htp.p('<s:element name="' || l_pretty_program_name || 'Response">');
    htp.p('<s:complexType>');
    htp.p('<s:sequence>');
    -- for now, we only support returning one (string) value
    htp.p('<s:element minOccurs="1" maxOccurs="1" name="' || l_pretty_program_name || 'Result" nillable="true" type="s:string" />');
    htp.p('</s:sequence>');
    htp.p('</s:complexType>');
    htp.p('</s:element>');
    
  end loop;  
  
  htp.p('</s:schema>');
  htp.p('</wsdl:types>');

  -----------
  -- messages
  -----------
  
  for i in l_programs.first .. l_programs.last loop
  
    l_pretty_program_name := pretty_str (l_programs(i).program_name);
  
    htp.p('<wsdl:message name="' || l_pretty_program_name || 'SoapIn">');
    htp.p('<wsdl:part name="parameters" element="tns:' || l_pretty_program_name || '" />');
    htp.p('</wsdl:message>');

    htp.p('<wsdl:message name="' || l_pretty_program_name || 'SoapOut">');
    htp.p('<wsdl:part name="parameters" element="tns:' || l_pretty_program_name || 'Response" />');
    htp.p('</wsdl:message>');

  end loop;

  --------
  -- ports
  --------

  htp.p('<wsdl:portType name="' || l_service_name || 'Soap">');

  for i in l_programs.first .. l_programs.last loop
  
    l_pretty_program_name := pretty_str (l_programs(i).program_name);

    htp.p('<wsdl:operation name="' || l_pretty_program_name || '">');
    htp.p('<wsdl:input message="tns:' || l_pretty_program_name || 'SoapIn" />');
    htp.p('<wsdl:output message="tns:' || l_pretty_program_name || 'SoapOut" />');
    htp.p('</wsdl:operation>');

  end loop;

  htp.p('</wsdl:portType>');

  -----------
  -- bindings
  -----------
  
  htp.p('<wsdl:binding name="' || l_service_name || 'Soap" type="tns:' || l_service_name || 'Soap">');

  for i in l_programs.first .. l_programs.last loop
  
    l_pretty_program_name := pretty_str (l_programs(i).program_name);

    htp.p('<soap:binding transport="http://schemas.xmlsoap.org/soap/http" />');
    htp.p('<wsdl:operation name="' || l_pretty_program_name || '">');
    htp.p('<soap:operation soapAction="' || g_target_namespace || '/' || lower(l_package_name) || '/' || lower(l_programs(i).program_name) || '" style="document" />');
    htp.p('<wsdl:input>');
    htp.p('<soap:body use="literal" />');
    htp.p('</wsdl:input>');
    htp.p('<wsdl:output>');
    htp.p('<soap:body use="literal" />');
    htp.p('</wsdl:output>');
    htp.p('</wsdl:operation>');

  end loop;
  
  htp.p('</wsdl:binding>');

  ----------
  -- service
  ----------
  htp.p('<wsdl:service name="' || l_service_name || '">');
  htp.p('<wsdl:port name="' || l_service_name || 'Soap" binding="tns:' || l_service_name || 'Soap">');
  htp.p('<soap:address location="' || g_protocol || '://' || owa_util.get_cgi_env('HTTP_HOST') || owa_util.get_cgi_env('SCRIPT_NAME') || '/' || g_schema_name || '.' || g_package_name || '.handle_request" />');
  htp.p('</wsdl:port>');
  htp.p('</wsdl:service>');

  htp.p('</wsdl:definitions>');

end wsdl;


procedure generate_soap_fault (p_error_code in number,
                               p_error_text in varchar2,
                               p_error_stack in varchar2)
as
  l_default_error_text varchar2(2000);
begin

  /*

  Purpose:   Generate SOAP fault

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  owa_util.mime_header('text/xml; charset=utf-8;', true);

  htp.p('<?xml version="1.0" encoding="utf-8"?>');
  htp.p('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">');
  htp.p('<soap:Body>');
  htp.p('<soap:Fault>');
  
  if p_error_code = g_application_error_code then
    htp.p('<faultcode>soap:Client</faultcode>');
    l_default_error_text := 'Invalid request';
  else
    htp.p('<faultcode>soap:Server</faultcode>');
    l_default_error_text := 'Request failed';
  end if;
  
  if g_debug_mode_enabled then
    htp.p('<faultstring>' || p_error_text || '</faultstring>');
    htp.p('<detail><message>' || p_error_stack || '</message><errorcode>' || p_error_code || '</errorcode></detail>');
  else
    htp.p('<faultstring>' || l_default_error_text || '</faultstring>');
    htp.p('<detail><message>Please contact the system administrator</message><errorcode>1</errorcode></detail>');
  end if;
  
  htp.p('</soap:Fault>');
  htp.p('</soap:Body>');
  htp.p('</soap:Envelope>');

end generate_soap_fault;


function parse_request (p_soap_action in varchar2,
                        p_soap_body in varchar2) return t_request
as

  l_soap_action                  varchar2(2000);
  l_soap_action_tab              apex_application_global.vc_arr2;
  
  l_parser                       dbms_xmlparser.parser;
  l_doc                          dbms_xmldom.domdocument;
  l_node                         dbms_xmldom.domnode;
  l_node_list                    dbms_xmldom.domnodelist;
  l_node_list_length             number;
  l_node_name                    varchar2(32000);
  l_node_value                   varchar2(32000);
  
  l_pos                          pls_integer;
  l_param_name                   varchar2(30);
  l_arguments                    t_argument_tab;
  
  l_returnvalue                  t_request;

begin

  /*

  Purpose:   Parse SOAP request

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  if p_soap_action is null then
    raise_error ('SOAP Action not specified!');
  end if;
  
  if p_soap_body is null then
    raise_error ('SOAP Body is empty!');
  end if;

  l_soap_action := replace(p_soap_action, '"', '');

  l_soap_action_tab := apex_util.string_to_table (l_soap_action, '/');
  
  l_returnvalue.package_name := l_soap_action_tab(l_soap_action_tab.last - 1);
  l_returnvalue.package_name := dbms_assert.sql_object_name (l_returnvalue.package_name);

  l_returnvalue.program_name := l_soap_action_tab(l_soap_action_tab.last);
  l_returnvalue.program_name := dbms_assert.simple_sql_name (l_returnvalue.program_name);
  
  l_returnvalue.operation_name := pretty_str (l_returnvalue.program_name);
  
  if not is_whitelisted (l_returnvalue.package_name, l_returnvalue.program_name) then
    if g_debug_mode_enabled then
      raise_error ('Package "' || l_returnvalue.package_name || '", program "' || l_returnvalue.program_name || '" is not on the whitelist, and therefore cannot be executed.');
    else
      raise_error ('Operation not authorized.');
    end if;
  end if;
  
  l_arguments := get_arguments (l_returnvalue.package_name, l_returnvalue.program_name);

  l_parser := dbms_xmlparser.newparser;
  dbms_xmlparser.parsebuffer (l_parser, p_soap_body);
  l_doc := dbms_xmlparser.getdocument (l_parser);
  dbms_xmlparser.freeparser (l_parser);

  l_node_list := dbms_xmldom.getelementsbytagname (l_doc, l_returnvalue.operation_name);

  -- should only be one node, now get its children
  l_node_list := dbms_xmldom.getchildnodes(dbms_xmldom.item(l_node_list, 0));
  l_node_list_length := dbms_xmldom.getlength (l_node_list);
  
  for l_count in 0..l_node_list_length - 1 loop

    l_node := dbms_xmldom.item (l_node_list, l_count);

    l_node_name := dbms_xmldom.getnodename (l_node);

    -- strip away namespace (if any) in parameter name
    l_pos := instr(l_node_name, ':');
    if l_pos > 0 then
      l_node_name := substr(l_node_name, l_pos + 1);
    end if;
    
    -- check parameter name against metadata, and get parameter datatype
    
    l_param_name := null;
    
    if l_arguments.count > 0 then
      for i in l_arguments.first .. l_arguments.last loop
        if upper(l_arguments(i).argument_name) = upper (l_node_name) then
          l_param_name := lower(l_arguments(i).argument_name);
          l_returnvalue.params (l_count).data_type := l_arguments(i).data_type;
          exit;
        end if;
      end loop;
    end if;

    if l_param_name is null then
      if g_debug_mode_enabled then
        raise_error ('Mismatch between actual and supplied parameters (argument count = ' || l_arguments.count || ', node = ' || l_node_name || ').');
      else
        raise_error ('Invalid parameters!');
      end if;
    end if;

    l_returnvalue.params (l_count).param_name := l_param_name;
    
    -- note: to get the actual value using getnodevalue, the child of the node must be retrieved
    -- see http://stackoverflow.com/questions/743031/retrieve-value-of-an-xml-element-in-oracle-pl-sql
    l_node_value := dbms_xmldom.getnodevalue(dbms_xmldom.getfirstchild(l_node));
    
    if l_returnvalue.params (l_count).data_type = 'DATE' then
      l_returnvalue.params (l_count).param_value_date := to_date(l_node_value, g_xml_date_format);
    elsif l_returnvalue.params (l_count).data_type = 'NUMBER' then
      l_returnvalue.params (l_count).param_value_number := to_number(l_node_value);
    else
      l_returnvalue.params (l_count).param_value_string := l_node_value;
    end if;
       
  end loop;

  dbms_xmldom.freenode (l_node);
  dbms_xmldom.freedocument (l_doc);

  return l_returnvalue;

end parse_request;


function execute_request (p_request in t_request) return t_response
as
  l_returnvalue t_response;
  l_sql         varchar2(32000);
  l_cursor_id   integer;
  l_rows        integer;
begin

  /*

  Purpose:   Print SOAP response

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  l_returnvalue.operation_name := p_request.operation_name;

  l_sql := 'begin :p__retval := to_clob( ' || p_request.package_name || '.' || p_request.program_name || ' (';

  if p_request.params.count > 0 then  
    for i in 0..p_request.params.count - 1 loop
      if i > 0 then
        l_sql := l_sql || ', ';
      end if;
      l_sql := l_sql || p_request.params(i).param_name || ' => :b' || i;
    end loop;
  end if;
  
  l_sql := l_sql || ')); end;';

  l_cursor_id := dbms_sql.open_cursor;
  dbms_sql.parse (l_cursor_id, l_sql, dbms_sql.native);

  dbms_sql.bind_variable (l_cursor_id, ':p__retval', l_returnvalue.result_clob);

  if p_request.params.count > 0 then  
    for i in 0..p_request.params.count - 1 loop
      if p_request.params(i).data_type = 'DATE' then
        dbms_sql.bind_variable (l_cursor_id, ':b' || i, p_request.params(i).param_value_date);
      elsif p_request.params(i).data_type = 'NUMBER' then
        dbms_sql.bind_variable (l_cursor_id, ':b' || i, p_request.params(i).param_value_number);
      else
        dbms_sql.bind_variable (l_cursor_id, ':b' || i, p_request.params(i).param_value_string);
      end if;
    end loop;
  end if;
  
  l_rows := dbms_sql.execute (l_cursor_id);

  dbms_sql.variable_value (l_cursor_id, ':p__retval', l_returnvalue.result_clob);
  dbms_sql.close_cursor (l_cursor_id);

  return l_returnvalue;

end execute_request;


procedure htp_print_clob (p_clob in clob,
                          p_add_newline in boolean := true)
as
  l_buffer   varchar2(32767);
  c_max_size constant integer := 8000;
  l_start    integer := 1;
begin

  /*

  Purpose:    print clob to HTTP buffer

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.01.2009  Created

  */
  
  if p_clob is not null then
  
    loop
      l_buffer := dbms_lob.substr (p_clob, c_max_size, l_start);
      exit when l_buffer is null;
      htp.prn (l_buffer);
      l_start := l_start + c_max_size;
    end loop ;
  
    if p_add_newline then
      htp.p;
    end if;  
    
  end if;

end htp_print_clob;


procedure print_response (p_response in t_response)
as
begin

  /*

  Purpose:   Print SOAP response

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */

  owa_util.mime_header('text/xml; charset=utf-8;', true);

  htp.p('<?xml version="1.0" encoding="utf-8"?>');
  htp.p('<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">');
  htp.p('<soap:Body>');
  htp.p('<' || p_response.operation_name || 'Response xmlns="' || g_target_namespace || '">');

  if p_response.result_clob is not null then
    htp.prn('<' || p_response.operation_name || 'Result>');
    htp_print_clob (dbms_xmlgen.convert(p_response.result_clob), p_add_newline => false);
    htp.prn('</' || p_response.operation_name || 'Result>');
  else
    htp.p('<' || p_response.operation_name || 'Result xsi:nil="true" />');  
  end if;

  htp.p('</' || p_response.operation_name || 'Response>');
  htp.p('</soap:Body>');
  htp.p('</soap:Envelope>');


end print_response;


procedure handle_request
as
  l_error_code                   number;
  l_error_text                   varchar2(4000);
  l_error_stack                  varchar2(4000);
  
  l_soap_action                  varchar2(2000);
  l_soap_body                    varchar2(32000);
  
  l_request                      t_request;
  l_response                     t_response;
  
begin

  /*

  Purpose:   Handle SOAP request

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */
  
  l_soap_action := coalesce(owa_util.get_cgi_env('HTTP_SOAPACTION'), owa_util.get_cgi_env('soapaction'));
  
  l_soap_body := owa_util.get_cgi_env('SOAP_BODY'); -- NOTE: there is a hard limit of 32k on each CGI variable... so keep requests short !

  l_request := parse_request (l_soap_action, l_soap_body);

  l_response := execute_request (l_request);

  print_response (l_response);

exception
  when others then
    l_error_code := sqlcode;
    l_error_text := substr(sqlerrm,1,4000);
    l_error_stack := substr(dbms_utility.format_error_backtrace,1,4000);
    rollback;
    generate_soap_fault (l_error_code, l_error_text, l_error_stack);
  
end handle_request;


end soap_server_pkg;
/

