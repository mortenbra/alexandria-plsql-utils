create or replace package body flex_ws_api
as

  /*

  Purpose:   Web Service callouts from PL/SQL

  Remarks:   By Jason Straub, see http://jastraub.blogspot.com/2008/06/flexible-web-service-api.html
             
  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.05.2012  Added to Alexandria Library because this is a prerequisite for the EWS (MS Exchange Web Service) API
  
  */


function blob2clobbase64 (
    p_blob in blob ) return clob
is
    pos         pls_integer         := 1;
    buffer      varchar2 (32767);
    res         clob;
    lob_len     integer             := dbms_lob.getlength (p_blob);
    l_width     pls_integer         := (76 / 4 * 3)-9;
begin
    dbms_lob.createtemporary (res, true);
    dbms_lob.open (res, dbms_lob.lob_readwrite);

    while (pos < lob_len) loop
        buffer :=
                utl_raw.cast_to_varchar2
                 (utl_encode.base64_encode (dbms_lob.substr (p_blob, l_width, pos)));

        dbms_lob.writeappend (res, length (buffer), buffer);

        pos := pos + l_width;
    end loop;

    return res;

end blob2clobbase64;

function clobbase642blob (
    p_clob in clob ) return blob
is
    pos         pls_integer         := 1;
    buffer      raw(36);
    res         blob;
    lob_len     integer             := dbms_lob.getlength (p_clob);
    l_width     pls_integer         := (76 / 4 * 3)-9;
begin
    dbms_lob.createtemporary (res, true);
    dbms_lob.open (res, dbms_lob.lob_readwrite);

    while (pos < lob_len) loop
        buffer := utl_encode.base64_decode(utl_raw.cast_to_raw(dbms_lob.substr (p_clob, l_width, pos)));

        dbms_lob.writeappend (res, utl_raw.length(buffer), buffer);

        pos := pos + l_width;
    end loop;

    return res;

end clobbase642blob;

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
    p_extra_headers     in wwv_flow_global.vc_arr2 default empty_vc_arr )
is
    l_clob clob;
    l_http_req utl_http.req;
    l_http_resp utl_http.resp;
    l_amount binary_integer := 8000;
    l_offset integer := 1;
    l_buffer varchar2(32000);
    l_db_charset   varchar2(100);
    l_env_lenb integer := 0;
    i integer := 0;
    l_headers wwv_flow_global.vc_arr2;
    l_response varchar2(2000);
    l_name          varchar2(256);
    l_hdr_value     varchar2(1024);
    l_hdr           header;
    l_hdrs          header_table;
begin

    -- determine database characterset, if not AL32UTF8, conversion will be necessary
    select value into l_db_charset from nls_database_parameters where parameter='NLS_CHARACTERSET';

    -- determine length for content-length header
    loop
        exit when wwv_flow_utilities.clob_to_varchar2(p_envelope,i*32767) is null;
        if l_db_charset = 'AL32UTF8' then
            l_env_lenb := l_env_lenb + lengthb(wwv_flow_utilities.clob_to_varchar2(p_envelope,i*32767));
        else
            l_env_lenb := l_env_lenb + utl_raw.length(
                    utl_raw.convert(utl_raw.cast_to_raw(wwv_flow_utilities.clob_to_varchar2(p_envelope,i*32767)),
                        'american_america.al32utf8','american_america.'||l_db_charset));
        end if;
        i := i + 1;
    end loop;

    -- set a proxy if required
    if apex_application.g_proxy_server is not null and p_proxy_override is null then
        utl_http.set_proxy (proxy => apex_application.g_proxy_server);
    elsif p_proxy_override is not null then
        utl_http.set_proxy (proxy => p_proxy_override);
    end if;

    --utl_http.set_persistent_conn_support(true);
    utl_http.set_transfer_timeout(600);

    -- set wallet if necessary
    if instr(lower(p_url),'https') = 1 then
        utl_http.set_wallet(p_wallet_path, p_wallet_pwd);
    end if;

    -- set cookies if necessary
    begin
        if g_request_cookies.count > 0 then
            utl_http.clear_cookies;
            utl_http.add_cookies(g_request_cookies);
        end if;
    exception when others then
        raise_application_error(-20001,'The provided cookie is invalid.');
    end;

    -- begin the request
    if wwv_flow_utilities.db_version like '9.%' then
        l_http_req := utl_http.begin_request(p_url, 'POST', 'HTTP/1.0');
    else
        l_http_req := utl_http.begin_request(p_url, 'POST');
    end if;

    -- set basic authentication if required
    if p_username is not null then
        utl_http.set_authentication (
            r => l_http_req,
            username => p_username,
            password => p_password,
            scheme => 'Basic',
            for_proxy => false );
    end if;

    -- set standard HTTP headers for a SOAP request
    utl_http.set_header(l_http_req, 'Proxy-Connection', 'Keep-Alive');
    if p_version = '1.2' then
        utl_http.set_header(l_http_req, 'Content-Type', 'application/soap+xml; charset=UTF-8; action="'||p_action||'";');
    else
        utl_http.set_header(l_http_req, 'SOAPAction', p_action);
        utl_http.set_header(l_http_req, 'Content-Type', 'text/xml; charset=UTF-8');
    end if;
    utl_http.set_header(l_http_req, 'Content-Length', l_env_lenb);

    -- set additional headers if supplied, these are separated by a colon (:) as name/value pairs
    for i in 1.. p_extra_headers.count loop
        l_headers := apex_util.string_to_table(p_extra_headers(i));
        utl_http.set_header(l_http_req, l_headers(1), l_headers(2));
    end loop;

    --set headers from g_request_headers
    for i in 1.. g_request_headers.count loop
        utl_http.set_header(l_http_req, g_request_headers(i).name, g_request_headers(i).value);
    end loop;

    -- read the envelope, convert to UTF8 if necessary, then write it to the HTTP request
    begin
        loop
            dbms_lob.read( p_envelope, l_amount, l_offset, l_buffer );
            if l_db_charset = 'AL32UTF8' then
                utl_http.write_text(l_http_req, l_buffer);
            else
                utl_http.write_raw(l_http_req,utl_raw.convert(utl_raw.cast_to_raw(l_buffer),'american_america.al32utf8','american_america.'||l_db_charset));
            end if;
            l_offset := l_offset + l_amount;
            l_amount := 8000;
        end loop;
    exception
        when no_data_found then
            null;
    end;

    -- get the response
    l_http_resp := utl_http.get_response(l_http_req);

    -- set response code, response http header and response cookies global
    g_status_code := l_http_resp.status_code;
    utl_http.get_cookies(g_response_cookies);
    for i in 1..utl_http.get_header_count(l_http_resp) loop
        utl_http.get_header(l_http_resp, i, l_name, l_hdr_value);
        l_hdr.name := l_name;
        l_hdr.value := l_hdr_value;
        l_hdrs(i) := l_hdr;
    end loop;

    g_headers := l_hdrs;

    -- put the response in a collection if necessary
    if p_collection_name is not null then

        apex_collection.create_or_truncate_collection(p_collection_name);

        dbms_lob.createtemporary( l_clob, FALSE );
        dbms_lob.open( l_clob, dbms_lob.lob_readwrite );
        begin
            loop
                utl_http.read_text(l_http_resp, l_buffer);
                dbms_lob.writeappend( l_clob, length(l_buffer), l_buffer );
            end loop;
        exception
            when others then
                if sqlcode <> -29266 then
                    raise;
                end if;
        end;

        apex_collection.add_member(
            p_collection_name   => p_collection_name,
            p_clob001           => l_clob);
    end if;
    --
    utl_http.end_response(l_http_resp);

end make_request;

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
    p_extra_headers     in wwv_flow_global.vc_arr2 default empty_vc_arr ) return xmltype
is
    l_clob clob;
    l_http_req utl_http.req;
    l_http_resp utl_http.resp;
    l_amount binary_integer := 8000;
    l_offset integer := 1;
    l_buffer varchar2(32000);
    l_db_charset   varchar2(100);
    l_env_lenb integer := 0;
    i integer := 0;
    l_headers wwv_flow_global.vc_arr2;
    l_response varchar2(2000);
    l_name          varchar2(256);
    l_hdr_value     varchar2(1024);
    l_hdr           header;
    l_hdrs          header_table;
    l_returnvalue   xmltype;
begin

    -- determine database characterset, if not AL32UTF8, conversion will be necessary
    select value into l_db_charset from nls_database_parameters where parameter='NLS_CHARACTERSET';

    -- determine length for content-length header
    loop
        exit when wwv_flow_utilities.clob_to_varchar2(p_envelope,i*32767) is null;
        if l_db_charset = 'AL32UTF8' then
            l_env_lenb := l_env_lenb + lengthb(wwv_flow_utilities.clob_to_varchar2(p_envelope,i*32767));
        else
            l_env_lenb := l_env_lenb + utl_raw.length(
                    utl_raw.convert(utl_raw.cast_to_raw(wwv_flow_utilities.clob_to_varchar2(p_envelope,i*32767)),
                        'american_america.al32utf8','american_america.'||l_db_charset));
        end if;
        i := i + 1;
    end loop;

    -- set a proxy if required
    if apex_application.g_proxy_server is not null and p_proxy_override is null then
        utl_http.set_proxy (proxy => apex_application.g_proxy_server);
    elsif p_proxy_override is not null then
        utl_http.set_proxy (proxy => p_proxy_override);
    end if;

    --utl_http.set_persistent_conn_support(true);
    utl_http.set_transfer_timeout(600);

    -- set wallet if necessary
    if instr(lower(p_url),'https') = 1 then
        utl_http.set_wallet(p_wallet_path, p_wallet_pwd);
    end if;

    -- set cookies if necessary
    begin
        if g_request_cookies.count > 0 then
            utl_http.clear_cookies;
            utl_http.add_cookies(g_request_cookies);
        end if;
    exception when others then
        raise_application_error(-20001,'The provided cookie is invalid.');
    end;

    -- begin the request
    if wwv_flow_utilities.db_version like '9.%' then
        l_http_req := utl_http.begin_request(p_url, 'POST', 'HTTP/1.0');
    else
        l_http_req := utl_http.begin_request(p_url, 'POST');
    end if;

    -- set basic authentication if required
    if p_username is not null then
        utl_http.set_authentication (
            r => l_http_req,
            username => p_username,
            password => p_password,
            scheme => 'Basic',
            for_proxy => false );
    end if;

    -- set standard HTTP headers for a SOAP request
    utl_http.set_header(l_http_req, 'Proxy-Connection', 'Keep-Alive');
    if p_version = '1.2' then
        utl_http.set_header(l_http_req, 'Content-Type', 'application/soap+xml; charset=UTF-8; action="'||p_action||'";');
    else
        utl_http.set_header(l_http_req, 'SOAPAction', p_action);
        utl_http.set_header(l_http_req, 'Content-Type', 'text/xml; charset=UTF-8');
    end if;
    utl_http.set_header(l_http_req, 'Content-Length', l_env_lenb);

    -- set additional headers if supplied, these are separated by a colon (:) as name/value pairs
    for i in 1.. p_extra_headers.count loop
        l_headers := apex_util.string_to_table(p_extra_headers(i));
        utl_http.set_header(l_http_req, l_headers(1), l_headers(2));
    end loop;

    --set headers from g_request_headers
    for i in 1.. g_request_headers.count loop
        utl_http.set_header(l_http_req, g_request_headers(i).name, g_request_headers(i).value);
    end loop;

    -- read the envelope, convert to UTF8 if necessary, then write it to the HTTP request
    begin
        loop
            dbms_lob.read( p_envelope, l_amount, l_offset, l_buffer );
            if l_db_charset = 'AL32UTF8' then
                utl_http.write_text(l_http_req, l_buffer);
            else
                utl_http.write_raw(l_http_req,utl_raw.convert(utl_raw.cast_to_raw(l_buffer),'american_america.al32utf8','american_america.'||l_db_charset));
            end if;
            l_offset := l_offset + l_amount;
            l_amount := 8000;
        end loop;
    exception
        when no_data_found then
            null;
    end;

    -- get the response
    l_http_resp := utl_http.get_response(l_http_req);

    -- set response code, response http header and response cookies global
    g_status_code := l_http_resp.status_code;
    utl_http.get_cookies(g_response_cookies);
    for i in 1..utl_http.get_header_count(l_http_resp) loop
        utl_http.get_header(l_http_resp, i, l_name, l_hdr_value);
        l_hdr.name := l_name;
        l_hdr.value := l_hdr_value;
        l_hdrs(i) := l_hdr;
    end loop;

    g_headers := l_hdrs;

    -- put the response in a clob
    dbms_lob.createtemporary( l_clob, FALSE );
    dbms_lob.open( l_clob, dbms_lob.lob_readwrite );
    begin
        loop
            utl_http.read_text(l_http_resp, l_buffer);
            dbms_lob.writeappend( l_clob, length(l_buffer), l_buffer );
        end loop;
    exception
        when others then
            if sqlcode <> -29266 then
                raise;
            end if;
    end;

    utl_http.end_response(l_http_resp);
    
    begin
        l_returnvalue := xmltype.createxml( l_clob );
    exception when others then
        if sqlcode = -31011 then -- invalid xml
            raise_application_error( -20001, 'HTTP response could not be converted to XML. Response was (first 1000 characters): ' || dbms_lob.substr( l_clob, 1000 ));
        end if;
    end;
    dbms_lob.freetemporary( l_clob );

    return l_returnvalue;
end make_request;

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
    p_wallet_pwd        in varchar2 default null )
return clob
is
    l_http_req      utl_http.req;
    l_http_resp     utl_http.resp;
    --
    l_body          clob default empty_clob();
    i               integer;
    l_env_lenb      number  := 0;
    l_db_charset    varchar2(100) := 'AL32UTF8';
    l_buffer        varchar2(32767);
    l_raw           raw(48);
    l_amount        number;
    l_offset        number;
    l_value         clob;
    l_url           varchar2(32767);
    l_parm_value    varchar2(32767);
    l_name          varchar2(256);
    l_hdr_value     varchar2(1024);
    l_hdr           header;
    l_hdrs          header_table;
begin

    -- determine database characterset, if not AL32UTF8, conversion will be necessary
    select value into l_db_charset from nls_database_parameters where parameter='NLS_CHARACTERSET';

    -- set a proxy if required
    if apex_application.g_proxy_server is not null and p_proxy_override is null then
        utl_http.set_proxy (proxy => apex_application.g_proxy_server);
    elsif p_proxy_override is not null then
        utl_http.set_proxy (proxy => p_proxy_override);
    end if;

    --utl_http.set_persistent_conn_support(TRUE);
    utl_http.set_transfer_timeout(180);

    if instr(lower(p_url),'https') = 1 then
        utl_http.set_wallet(p_wallet_path, p_wallet_pwd);
    end if;

    if dbms_lob.getlength(p_body) = 0 then
        for i in 1.. p_parm_name.count loop
            if p_http_method = 'GET' then
                l_parm_value := apex_util.url_encode(p_parm_value(i));
            else
                l_parm_value := p_parm_value(i);
            end if;
            if i = 1 then
                l_body := p_parm_name(i)||'='||l_parm_value;
            else
                l_body := l_body||'&'||p_parm_name(i)||'='||l_parm_value;
            end if;
        end loop;
    else
        l_body := p_body;
    end if;

    i := 0;

    l_url := p_url;

    if p_http_method = 'GET' then
        l_url := l_url||'?'||wwv_flow_utilities.clob_to_varchar2(l_body);
    end if;

    -- determine length in bytes of l_body;
    if dbms_lob.getlength(p_body_blob) > 0 then
        l_env_lenb := dbms_lob.getlength(p_body_blob);
    else
        loop
            exit when wwv_flow_utilities.clob_to_varchar2(l_body,i*32767) is null;
            if l_db_charset = 'AL32UTF8' then
                l_env_lenb := l_env_lenb + lengthb(wwv_flow_utilities.clob_to_varchar2(l_body,i*32767));
            else
                l_env_lenb := l_env_lenb + utl_raw.length(
                    utl_raw.convert(utl_raw.cast_to_raw(wwv_flow_utilities.clob_to_varchar2(l_body,i*32767)),
                        'american_america.al32utf8','american_america.' || l_db_charset));
            end if;
            i := i + 1;
        end loop;
    end if;

    -- set cookies if necessary
    begin
        if g_request_cookies.count > 0 then
            utl_http.clear_cookies;
            utl_http.add_cookies(g_request_cookies);
        end if;
    exception when others then
        raise_application_error(-20001,'The provided cookie is invalid.');
    end;

    begin
        l_http_req := utl_http.begin_request(l_url, p_http_method);
        -- set basic authentication if necessary
        if p_username is not null then
             utl_http.set_authentication(l_http_req, p_username, p_password);
        end if;
        utl_http.set_header(l_http_req, 'Proxy-Connection', 'Keep-Alive');
        if p_http_method != 'GET' then
            utl_http.set_header(l_http_req, 'Content-Length', l_env_lenb);
        end if;
        -- set additional headers if supplied, these are separated by a colon (:) as name/value pairs
        for i in 1.. p_http_headers.count loop
            utl_http.set_header(l_http_req, p_http_headers(i), p_http_hdr_values(i));
        end loop;
    exception when others then
        raise_application_error(-20001,'The URL provided is invalid or you need to set a proxy.');
    end;

    --set headers from g_request_headers
    for i in 1.. g_request_headers.count loop
        utl_http.set_header(l_http_req, g_request_headers(i).name, g_request_headers(i).value);
    end loop;

    --
    l_amount := 8000;
    l_offset := 1;
    if p_http_method != 'GET' then
        if dbms_lob.getlength(l_body) > 0 then
            begin
                loop
                    dbms_lob.read( l_body, l_amount, l_offset, l_buffer );
                    if l_db_charset = 'AL32UTF8' then
                        utl_http.write_text(l_http_req, l_buffer);
                    else
                        utl_http.write_raw(l_http_req,
                                           utl_raw.convert(utl_raw.cast_to_raw(l_buffer),
                                                           'american_america.al32utf8',
                                                           'american_america.' || l_db_charset
                                       )
                        );
                    end if;
                    l_offset := l_offset + l_amount;
                    l_amount := 8000;
                end loop;
            exception
                when no_data_found then
                    null;
            end;
        elsif dbms_lob.getlength(p_body_blob) > 0 then
            begin
                l_amount := 48;
                while (l_offset < l_env_lenb) loop
                    dbms_lob.read(p_body_blob, l_amount, l_offset, l_raw);
                    utl_http.write_raw(l_http_req, l_raw);
                    l_offset := l_offset + l_amount;
                end loop;
            exception
                when no_data_found then
                    null;
            end;
        end if;
    end if;
    --
    begin
        l_http_resp := utl_http.get_response(l_http_req);
    exception when others then
        raise_application_error(-20001,'The URL provided is invalid or you need to set a proxy.');
    end;
    --

    -- set response code, response http header and response cookies global
    g_status_code := l_http_resp.status_code;
    utl_http.get_cookies(g_response_cookies);
    for i in 1..utl_http.get_header_count(l_http_resp) loop
        utl_http.get_header(l_http_resp, i, l_name, l_hdr_value);
        l_hdr.name := l_name;
        l_hdr.value := l_hdr_value;
        l_hdrs(i) := l_hdr;
    end loop;

    g_headers := l_hdrs;

    --
    dbms_lob.createtemporary( l_value, FALSE );
    dbms_lob.open( l_value, dbms_lob.lob_readwrite );

    begin
        loop
            utl_http.read_text(l_http_resp, l_buffer);
            dbms_lob.writeappend( l_value, length(l_buffer), l_buffer );
        end loop;
    exception
        when others then
            if sqlcode <> -29266 then
                raise;
            end if;
    end;
    --
    utl_http.end_response(l_http_resp);

    return l_value;

end make_rest_request;

function parse_xml (
    p_xml               in xmltype,
    p_xpath             in varchar2,
    p_ns                in varchar2 default null ) return varchar2
is
    l_response          varchar2(32767);
begin

    l_response := dbms_xmlgen.convert(p_xml.extract(p_xpath,p_ns).getstringval(),1);

    return l_response;

exception when others then
    if sqlcode = -30625 then -- path not found
        return null;
    end if;
end parse_xml;

function parse_xml_clob (
    p_xml               in xmltype,
    p_xpath             in varchar2,
    p_ns                in varchar2 default null ) return clob
is
    l_response          clob;
begin

    l_response := p_xml.extract(p_xpath,p_ns).getclobval();

    return l_response;

exception when others then
    if sqlcode = -30625 then -- path not found
        return null;
    end if;
end parse_xml_clob;

function parse_response (
    p_collection_name   in varchar2,
    p_xpath             in varchar2,
    p_ns                in varchar2 default null ) return varchar2
is
    l_response          varchar2(32767);
    l_xml               xmltype;
begin

    for c1 in (select clob001
                 from apex_collections
                where collection_name = p_collection_name ) loop
        l_xml := xmltype.createxml(c1.clob001);
        exit;
    end loop;

    l_response := parse_xml(l_xml, p_xpath, p_ns);

    return l_response;

exception when others then
    if sqlcode = -31011 then -- its not xml
        return null;
    end if;
end parse_response;

function parse_response_clob (
    p_collection_name   in varchar2,
    p_xpath             in varchar2,
    p_ns                in varchar2 default null ) return clob
is
    l_response          clob;
    l_xml               xmltype;
begin

    for c1 in (select clob001
                 from apex_collections
                where collection_name = p_collection_name ) loop
        l_xml := xmltype.createxml(c1.clob001);
        exit;
    end loop;

    l_response := parse_xml_clob(l_xml, p_xpath, p_ns);

    return l_response;

exception when others then
    if sqlcode = -31011 then -- its not xml
        return null;
    end if;
end parse_response_clob;

end flex_ws_api;
/
