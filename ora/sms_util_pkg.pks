create or replace package sms_util_pkg
as
 
  /*
 
  Purpose:      Package handles sending of SMS (Short Message Service) to mobile phones via an SMS gateway
 
  Remarks:      The package provides a generic interface and attempts to support any SMS gateway that provides an HTTP(S) (GET) interface
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     24.08.2014  Created
 
  */

  -- gateway configuration
  type t_gateway_config is record (
    send_sms_url                 varchar2(4000),
    username                     varchar2(255),
    password                     varchar2(255),
    response_format              varchar2(30),
    response_error_path          varchar2(4000), -- either an xpath or jsonpath expression
    response_error_namespace     varchar2(4000), -- xml namespace
    response_error_parser        varchar2(4000)  -- a custom PL/SQL error parsing function (must accept a clob parameter and return a varchar2 containing error message)
  );

  -- response formats
  g_format_xml                   constant varchar2(255) := 'xml';
  g_format_json                  constant varchar2(255) := 'json';
  g_format_custom                constant varchar2(255) := 'custom';

  -- internal variable used for dynamic PL/SQL evaluation
  g_exec_result_string           varchar2(4000);
 
  -- set SSL wallet properties
  procedure set_wallet (p_wallet_path in varchar2,
                        p_wallet_password in varchar2);

  -- set gateway configuration
  procedure set_gateway_config (p_gateway_config in t_gateway_config);

  -- send SMS message
  procedure send_sms (p_message in varchar2,
                      p_to in varchar2,
                      p_from in varchar2,
                      p_attr1 in varchar2 := null,
                      p_attr2 in varchar2 := null,
                      p_attr3 in varchar2 := null,
                      p_username in varchar2 := null,
                      p_password in varchar2 := null);

end sms_util_pkg;
/

