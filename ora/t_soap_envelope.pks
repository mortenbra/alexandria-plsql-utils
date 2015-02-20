create or replace type t_soap_envelope as object (

  /*

  Purpose:    Object type to handle SOAP envelopes for web service calls

  Remarks:  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     17.02.2009  Created
  MBR     11.05.2011  Added request start date, support for clob parameters
  
  */

  -- public properties
  service_namespace       varchar2(255),
  service_method          varchar2(4000),
  service_host            varchar2(4000),
  service_path            varchar2(4000),
  service_url             varchar2(4000),
  soap_action             varchar2(4000),
  soap_namespace          varchar2(255),
  request_start_date      date,
  envelope                clob,
  
  -- private properties
  m_parameters            clob,
  
  constructor function t_soap_envelope (p_service_host in varchar2,
                                        p_service_path in varchar2,
                                        p_service_method in varchar2,
                                        p_service_namespace in varchar2 := null,
                                        p_soap_namespace in varchar2 := null,
                                        p_soap_action in varchar2 := null) return self as result,
  
  member procedure add_param (p_name in varchar2,
                              p_value in varchar2,
                              p_type in varchar2 := null),
                                  
  member procedure add_param_clob (p_name in varchar2,
                                   p_value in clob,
                                   p_type in varchar2 := null),

  member procedure add_xml (p_xml in clob),

  member procedure build_env,
  
  member procedure debug_envelope
  
  ); 
/