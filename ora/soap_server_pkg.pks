create or replace package soap_server_pkg
as

  /*

  Purpose:   Package implements a SOAP server in PL/SQL

  Remarks:   see http://www.w3.org/TR/2000/NOTE-SOAP-20000508/

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     25.12.2010  Created
  
  */

  -- generate WSDL for service (package)
  procedure wsdl (s in varchar2);

  -- handle SOAP request
  procedure handle_request;

end soap_server_pkg;
/

