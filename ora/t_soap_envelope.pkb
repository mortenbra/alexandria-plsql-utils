create or replace type body t_soap_envelope
as
  
  /*

  Purpose:    Object type to handle SOAP envelopes for web service calls

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     17.02.2009  Created
  
  */

  -- see http://thinkoracle.blogspot.com/2005/06/oop-in-plsql-yep.html
  -- see http://plsql-object-types.blogspot.com/  

  /*
  
  All methods in an object type accept an instance of that type as their first parameter. The name of this built-in parameter is SELF. Whether declared implicitly or explicitly, SELF is always the first parameter passed to a method.
  In member functions, if SELF is not declared, its parameter mode defaults to IN. However, in member procedures, if SELF is not declared, its parameter mode defaults to IN OUT.
  
  */

  constructor function t_soap_envelope (p_service_host in varchar2,
                                        p_service_path in varchar2,
                                        p_service_method in varchar2,
                                        p_service_namespace in varchar2 := null,
                                        p_soap_namespace in varchar2 := null,
                                        p_soap_action in varchar2 := null) return self as result
  as
  begin
    self.request_start_date := sysdate;
    self.service_host := p_service_host;
    self.service_path := p_service_path;
    self.service_method := p_service_method;
    self.service_namespace := nvl(p_service_namespace, 'xmlns="' || p_service_host || '/"');
    self.service_url := p_service_host || '/' || p_service_path;
    self.soap_namespace := nvl(p_soap_namespace, 'soap');
    self.soap_action := nvl(p_soap_action, p_service_host || '/' || p_service_method);
    self.envelope := '';
    build_env;
    return;
  end;


  member procedure add_param (p_name in varchar2,
                              p_value in varchar2,
                              p_type in varchar2 := null)
  as
  begin
    
    if p_type is null then
      m_parameters := m_parameters || chr(13) || '  <' || p_name || '>' || p_value || '</' || p_name || '>';
    else
      m_parameters := m_parameters || chr(13) || '  <' || p_name || ' xsi:type="' || p_type || '">' || p_value || '</' || p_name || '>';
    end if;
    build_env;
  
  end add_param;
  

  member procedure add_param_clob (p_name in varchar2,
                                   p_value in clob,
                                   p_type in varchar2 := null)
  as
  begin
    
    if p_type is null then
      m_parameters := m_parameters || chr(13) || '  <' || p_name || '>' || p_value || '</' || p_name || '>';
    else
      m_parameters := m_parameters || chr(13) || '  <' || p_name || ' xsi:type="' || p_type || '">' || p_value || '</' || p_name || '>';
    end if;
    build_env;
  
  end add_param_clob;


  member procedure add_xml (p_xml in clob)
  as
  begin
    
    m_parameters := m_parameters || chr(13) || p_xml;
    build_env;
  
  end add_xml;


  member procedure build_env (self in out t_soap_envelope)
  as
  begin
    
    self.envelope := '<' || self.soap_namespace || ':Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:' || self.soap_namespace || '="http://schemas.xmlsoap.org/soap/envelope/">' ||
             '<' || self.soap_namespace || ':Body>' ||
               '<' || self.service_method || ' ' || self.service_namespace || '>' ||
                   self.m_parameters || chr(13) ||
               '</' || self.service_method || '>' ||
             '</' || self.soap_namespace || ':Body>' ||
           '</' || self.soap_namespace || ':Envelope>';    
          
  end build_env;


  member procedure debug_envelope
  as
    i      pls_integer;
    l_len  pls_integer;
  begin
    
    if envelope is not null then
    
      i := 1; l_len := length(envelope);
      
      while (i <= l_len) loop
        dbms_output.put_line(substr(envelope, i, 32000));
        i := i + 32000;
      end loop;
      
    else
      dbms_output.put_line ('WARNING: The envelope is empty...');
    end if;
  
  
  end debug_envelope;

end;
/

