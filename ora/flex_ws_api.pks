create or replace package flex_ws_api
as

  /*

  Purpose:   Web Service callouts from PL/SQL

  Remarks:   By Jason Straub, see http://jastraub.blogspot.com/2008/06/flexible-web-service-api.html
             
  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.05.2012  Added to Alexandria Library because this is a prerequisite for the EWS (MS Exchange Web Service) API
  
  */


empty_vc_arr wwv_flow_global.vc_arr2;

g_request_cookies   utl_http.cookie_table;
g_response_cookies  utl_http.cookie_table;

type header is record (name varchar2(256), value varchar2(1024));
type header_table is table of header index by binary_integer;

g_headers           header_table;
g_request_headers   header_table;

g_status_code       pls_integer;


function blob2clobbase64 (
    p_blob in blob ) return clob;

function clobbase642blob (
    p_clob in clob ) return blob;

procedure make_request (
    p_url               in varchar2,
    p_action            in varchar2 default null,
    p_version           in varchar2 default '1.1',
    p_collection_name   in varchar2 default null,
    p_envelope          in clob,
    p_username          in varchar2 default null,
    p_password          in varchar2 default null,
    p_proxy_override    in varchar2 default null,
    p_wallet_path       in varchar2 default null,
    p_wallet_pwd        in varchar2 default null,
    p_extra_headers     in wwv_flow_global.vc_arr2 default empty_vc_arr );

function make_request (
    p_url               in varchar2,
    p_action            in varchar2 default null,
    p_version           in varchar2 default '1.1',
    p_envelope          in clob,
    p_username          in varchar2 default null,
    p_password          in varchar2 default null,
    p_proxy_override    in varchar2 default null,
    p_wallet_path       in varchar2 default null,
    p_wallet_pwd        in varchar2 default null,
    p_extra_headers     in wwv_flow_global.vc_arr2 default empty_vc_arr ) return xmltype;

function make_rest_request(
    p_url               in varchar2,
    p_http_method       in varchar2,
    p_username          in varchar2 default null,
    p_password          in varchar2 default null,
    p_proxy_override    in varchar2 default null,
    p_body              in clob default empty_clob(),
    p_body_blob         in blob default empty_blob(),
    p_parm_name         in wwv_flow_global.vc_arr2 default empty_vc_arr,
    p_parm_value        in wwv_flow_global.vc_arr2 default empty_vc_arr,
    p_http_headers      in wwv_flow_global.vc_arr2 default empty_vc_arr,
    p_http_hdr_values   in wwv_flow_global.vc_arr2 default empty_vc_arr,
    p_wallet_path       in varchar2 default null,
    p_wallet_pwd        in varchar2 default null ) return clob;

function parse_xml (
    p_xml               in xmltype,
    p_xpath             in varchar2,
    p_ns                in varchar2 default null ) return varchar2;

function parse_xml_clob (
    p_xml               in xmltype,
    p_xpath             in varchar2,
    p_ns                in varchar2 default null ) return clob;

function parse_response (
    p_collection_name   in varchar2,
    p_xpath             in varchar2,
    p_ns                in varchar2 default null ) return varchar2;

function parse_response_clob (
    p_collection_name   in varchar2,
    p_xpath             in varchar2,
    p_ns                in varchar2 default null ) return clob;

end flex_ws_api;
/
