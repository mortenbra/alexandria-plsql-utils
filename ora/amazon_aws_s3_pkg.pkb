create or replace package body amazon_aws_s3_pkg
as

  /*

  Purpose:   PL/SQL wrapper package for Amazon AWS S3 API

  Remarks:   inspired by the whitepaper "Building an Amazon S3 Client with Application Express 4.0" by Jason Straub
             see http://jastraub.blogspot.com/2011/01/building-amazon-s3-client-with.html

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     09.01.2011  Created
  
  */

  g_aws_url_s3             constant varchar2(255) := 'http://s3.amazonaws.com/';
  g_aws_host_s3            constant varchar2(255) := 's3.amazonaws.com';
  g_aws_namespace_s3       constant varchar2(255) := 'http://s3.amazonaws.com/doc/2006-03-01/';
  g_aws_namespace_s3_full  constant varchar2(255) := 'xmlns="' || g_aws_namespace_s3 || '"';

  g_date_format_xml        constant varchar2(30) := 'YYYY-MM-DD"T"HH24:MI:SS".000Z"';


procedure raise_error (p_error_message in varchar2)
as
begin

  /*

  Purpose:   raise error

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     15.01.2011  Created
  
  */
  
  raise_application_error (-20000, p_error_message);

end raise_error;


procedure check_for_errors (p_clob in clob)
as
  l_xml xmltype;
begin

  /*

  Purpose:   check for errors (clob)

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     15.01.2011  Created
  
  */

  if (p_clob is not null) and (length(p_clob) > 0) then

    l_xml := xmltype (p_clob);

    if l_xml.existsnode('/Error') = 1 then
      debug_pkg.print (l_xml);
      raise_error (l_xml.extract('/Error/Message/text()').getstringval());
    end if;
    
  end if;

end check_for_errors;


procedure check_for_errors (p_xml in xmltype)
as
begin

  /*

  Purpose:   check for errors (XMLType)

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     15.01.2011  Created
  
  */

  if p_xml.existsnode('/Error') = 1 then
    debug_pkg.print (p_xml);
    raise_error (p_xml.extract('/Error/Message/text()').getstringval());
  end if;

end check_for_errors;


function check_for_redirect (p_clob in clob) return varchar2
as
  l_xml                          xmltype;
  l_returnvalue                  varchar2(4000);
begin

  /*

  Purpose:   check for redirect

  Remarks:   Used by the "delete bucket" procedure, by Jeffrey Kemp
             see http://code.google.com/p/plsql-utils/issues/detail?id=14
             "One thing I found when testing was that if the bucket is not in the US standard region,
              Amazon seems to respond with a TemporaryRedirect error.
              If the same request is re-requested to the indicated URL it works."

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     16.02.2013  Created, based on code by Jeffrey Kemp

  */

  if (p_clob is not null) and (length(p_clob) > 0) then

    l_xml := xmltype (p_clob);

    if l_xml.existsnode('/Error') = 1 then

      if l_xml.extract('/Error/Code/text()').getStringVal = 'TemporaryRedirect' then
        l_returnvalue := l_xml.extract('/Error/Endpoint/text()').getStringVal;
        debug_pkg.printf('Temporary Redirect to %1', l_returnvalue);
      end if;

    end if;

  end if;
  
  return l_returnvalue;

end check_for_redirect;


function make_request (p_url in varchar2,
                       p_http_method in varchar2,
                       p_header_names in t_str_array,
                       p_header_values in t_str_array,
                       p_request_blob in blob := null,
                       p_request_clob in clob := null) return clob
as
  l_http_req     utl_http.req;
  l_http_resp    utl_http.resp;

  l_amount       binary_integer := 32000;
  l_offset       integer := 1;
  l_buffer       varchar2(32000);
  l_buffer_raw   raw(32000);

  l_response     varchar2(2000);
  l_returnvalue  clob;

begin

  /*

  Purpose:   make HTTP request

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     15.01.2011  Created
  
  */
  
  debug_pkg.printf('%1 %2', p_http_method, p_url);

  l_http_req := utl_http.begin_request(p_url, p_http_method);
  
  if p_header_names.count > 0 then
    for i in p_header_names.first .. p_header_names.last loop
      --debug_pkg.printf('%1: %2', p_header_names(i), p_header_values(i));
      utl_http.set_header(l_http_req, p_header_names(i), p_header_values(i));
    end loop;
  end if;
  
  if p_request_blob is not null then

    begin
      loop
        dbms_lob.read (p_request_blob, l_amount, l_offset, l_buffer_raw);
        utl_http.write_raw (l_http_req, l_buffer_raw);
        l_offset := l_offset + l_amount;
        l_amount := 32000;
      end loop;
    exception
      when no_data_found then
        null;
    end;

  elsif p_request_clob is not null then
  
    begin
      loop
        dbms_lob.read (p_request_clob, l_amount, l_offset, l_buffer);
        utl_http.write_text (l_http_req, l_buffer);
        l_offset := l_offset + l_amount;
        l_amount := 32000;
      end loop;
    exception
      when no_data_found then
        null;
    end;

  end if;

  l_http_resp := utl_http.get_response(l_http_req);

  dbms_lob.createtemporary (l_returnvalue, false);
  dbms_lob.open (l_returnvalue, dbms_lob.lob_readwrite);

  begin
    loop
      utl_http.read_text (l_http_resp, l_buffer);
      dbms_lob.writeappend (l_returnvalue, length(l_buffer), l_buffer);
    end loop;
  exception
    when others then
      if sqlcode <> -29266 then
        raise;
      end if;
  end;

  utl_http.end_response (l_http_resp);
  
  return l_returnvalue;

end make_request;


function get_url (p_bucket_name in varchar2,
                  p_key in varchar2 := null) return varchar2
as
  l_returnvalue varchar2(4000);
begin

  /*

  Purpose:   construct a valid URL

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.03.2011  Created
  
  */

  l_returnvalue := 'http://' || p_bucket_name || '.' || g_aws_host_s3 || '/' || p_key;
  
  return l_returnvalue;
  
end get_url;


function get_host (p_bucket_name in varchar2) return varchar2
as
  l_returnvalue varchar2(4000);
begin

  /*

  Purpose:   construct a valid host string

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.03.2011  Created
  
  */

  l_returnvalue := p_bucket_name || '.' || g_aws_host_s3;
  
  return l_returnvalue;
  
end get_host;


function get_bucket_list return t_bucket_list
as
  l_clob                         clob;
  l_xml                          xmltype;

  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);
  
  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();

  l_count                        pls_integer := 0;
  l_returnvalue                  t_bucket_list;
  
begin

  /*

  Purpose:   get buckets

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     09.01.2011  Created
  
  */

  l_date_str := amazon_aws_auth_pkg.get_date_string;
  l_auth_str := amazon_aws_auth_pkg.get_auth_string ('GET' || chr(10) || chr(10) || chr(10) || l_date_str || chr(10) || '/');

  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := g_aws_host_s3;

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;

  l_clob := make_request (g_aws_url_s3, 'GET', l_header_names, l_header_values, null);

  if (l_clob is not null) and (length(l_clob) > 0) then
  
    l_xml := xmltype (l_clob);
    
    check_for_errors (l_xml);

    for l_rec in (
      select extractValue(value(t), '*/Name', g_aws_namespace_s3_full) as bucket_name,
        extractValue(value(t), '*/CreationDate', g_aws_namespace_s3_full) as creation_date
      from table(xmlsequence(l_xml.extract('//ListAllMyBucketsResult/Buckets/Bucket', g_aws_namespace_s3_full))) t
      ) loop
      l_count := l_count + 1;
      l_returnvalue(l_count).bucket_name := l_rec.bucket_name;
      l_returnvalue(l_count).creation_date := to_date(l_rec.creation_date, g_date_format_xml);
    end loop;
    
  end if;

  return l_returnvalue;

end get_bucket_list;


function get_bucket_tab return t_bucket_tab pipelined
as
  l_bucket_list                  t_bucket_list;
begin

  /*

  Purpose:   get buckets

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.01.2011  Created
  
  */
  
  l_bucket_list := get_bucket_list;
  
  for i in 1 .. l_bucket_list.count loop
    pipe row (l_bucket_list(i));
  end loop;
  
  return;

end get_bucket_tab;


procedure new_bucket (p_bucket_name in varchar2,
                      p_region in varchar2 := null)
as

  l_request_body                 clob;
  l_clob                         clob;
  l_xml                          xmltype;

  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);
  
  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();

begin

  /*

  Purpose:   create bucket

  Remarks:   *** bucket names must be unique across all of Amazon S3 ***
  
             see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     15.01.2011  Created
  
  */
  
  l_date_str := amazon_aws_auth_pkg.get_date_string;

  if p_region is not null then
    l_auth_str := amazon_aws_auth_pkg.get_auth_string ('PUT' || chr(10) || chr(10) || 'text/plain' || chr(10) || l_date_str || chr(10) || '/' || p_bucket_name || '/');
  else
    l_auth_str := amazon_aws_auth_pkg.get_auth_string ('PUT' || chr(10) || chr(10) || chr(10) || l_date_str || chr(10) || '/' || p_bucket_name || '/');
  end if;

  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := get_host(p_bucket_name);

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;
  
  if p_region is not null then

    l_request_body := '<CreateBucketConfiguration ' || g_aws_namespace_s3_full || '><LocationConstraint>' || p_region || '</LocationConstraint></CreateBucketConfiguration>';

    l_header_names.extend;
    l_header_names(4) := 'Content-Type';
    l_header_values.extend;
    l_header_values(4) := 'text/plain';

    l_header_names.extend;
    l_header_names(5) := 'Content-Length';
    l_header_values.extend;
    l_header_values(5) := length(l_request_body);

  end if;

  l_clob := make_request (get_url (p_bucket_name), 'PUT', l_header_names, l_header_values, null, l_request_body);
  
  check_for_errors (l_clob);

end new_bucket;


function get_bucket_region (p_bucket_name in varchar2) return varchar2
as

  l_clob                         clob;
  l_xml                          xmltype;

  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);
  
  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();
  
  l_returnvalue                  varchar2(255);

begin

  /*

  Purpose:   get bucket region

  Remarks:   see http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
  
             note that the region will be NULL for buckets in the default region (US)

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     03.03.2011  Created
  
  */

  l_date_str := amazon_aws_auth_pkg.get_date_string;
  l_auth_str := amazon_aws_auth_pkg.get_auth_string ('GET' || chr(10) || chr(10) || chr(10) || l_date_str || chr(10) || '/' || p_bucket_name || '/?location');

  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := get_host(p_bucket_name);

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;

  l_clob := make_request (get_url(p_bucket_name) || '?location', 'GET', l_header_names, l_header_values);

  if (l_clob is not null) and (length(l_clob) > 0) then
  
    l_xml := xmltype (l_clob);
    
    check_for_errors (l_xml);
    
    if l_xml.existsnode('/LocationConstraint', g_aws_namespace_s3_full) = 1 then
      -- see http://pbarut.blogspot.com/2006/11/ora-30625-and-xmltype.html
      if l_xml.extract('/LocationConstraint/text()', g_aws_namespace_s3_full) is not null then
        l_returnvalue := l_xml.extract('/LocationConstraint/text()', g_aws_namespace_s3_full).getstringval();
      else
        l_returnvalue := null;
      end if;
    end if;
    
  end if;

  return l_returnvalue;

end get_bucket_region;


procedure get_object_list (p_bucket_name                 in varchar2,
                           p_prefix                      in varchar2,
                           p_max_keys                    in number,
                           p_list                       out t_object_list,
                           p_next_continuation_token in out varchar2)
as
  l_clob                         clob;
  l_xml                          xmltype;
  l_xml_is_truncated             xmltype;
  l_xml_next_continuation        xmltype;

  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);

  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();

  l_returnvalue                  t_object_list;

begin

  /*

  Purpose:   get objects

  Remarks:   see http://docs.aws.amazon.com/AmazonS3/latest/API/v2-RESTBucketGET.html
  
             see http://code.google.com/p/plsql-utils/issues/detail?id=16
  
             "I've rewritten get_object_list as an internal procedure that uses the "marker" parameter,
             so that get_object_tab can now call the Amazon API multiple times to return the complete set of objects.
             The get_object_list function remains functionally unchanged in this version - it just returns one set of objects -
             it could be enhanced to support the marker parameter as well, I guess,
             but I'd rather not expose that sort of thing to the caller personally.
             The nice thing about the pipelined function is that the subsequent calls to Amazon
             will only be executed if the client actually fetches all the rows."

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     15.01.2011  Created
  JKEMP   14.08.2012  Rewritten as private procedure, see remarks above
  KJS     06.10.2016  Modified to use newest S3 API which performs much better on large buckets. Changed for-loop to bulk operation.

  */

  l_date_str := amazon_aws_auth_pkg.get_date_string;
  l_auth_str := amazon_aws_auth_pkg.get_auth_string ('GET' || chr(10) || chr(10) || chr(10) || l_date_str || chr(10) || '/' || p_bucket_name || '/');

  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := get_host (p_bucket_name);

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;

  if p_next_continuation_token is not null then
    l_clob := make_request (get_url(p_bucket_name) || '?list-type=2&continuation-token=' || utl_url.escape(p_next_continuation_token) || '&max-keys=' || p_max_keys || '&prefix=' || utl_url.escape(p_prefix), 'GET', l_header_names, l_header_values, null);
  else
    l_clob := make_request (get_url(p_bucket_name) || '?list-type=2&max-keys=' || p_max_keys || '&prefix=' || utl_url.escape(p_prefix), 'GET', l_header_names, l_header_values, null);
  end if;
  if (l_clob is not null) and (length(l_clob) > 0) then

    l_xml := xmltype (l_clob);

    check_for_errors (l_xml);

    select extractValue(value(t), '*/Key', g_aws_namespace_s3_full),
      extractValue(value(t), '*/Size', g_aws_namespace_s3_full),
      to_date(extractValue(value(t), '*/LastModified', g_aws_namespace_s3_full), g_date_format_xml)
    bulk collect into l_returnvalue
    from table(xmlsequence(l_xml.extract('//ListBucketResult/Contents', g_aws_namespace_s3_full))) t;
      
    -- check if this is the last set of data or not, and set the in/out p_next_continuation_token as expected
    l_xml_is_truncated := l_xml.extract('//ListBucketResult/IsTruncated/text()', g_aws_namespace_s3_full);
    
    if l_xml_is_truncated is not null and l_xml_is_truncated.getStringVal = 'true' then
      l_xml_next_continuation := l_xml.extract('//ListBucketResult/NextContinuationToken/text()', g_aws_namespace_s3_full);
      if l_xml_next_continuation is not null then
        p_next_continuation_token := l_xml_next_continuation.getStringVal;
      else
        p_next_continuation_token := null;
      end if;
    else
      p_next_continuation_token := null;
    end if;
  end if;

  p_list := l_returnvalue;

end get_object_list;


function get_object_list (p_bucket_name in varchar2,
                          p_prefix in varchar2 := null,
                          p_max_keys in number := null) return t_object_list
as
  l_object_list                  t_object_list;
  l_next_continuation_token      varchar2(4000);
begin

  /*

  Purpose:   get objects

  Remarks:   see http://docs.amazonwebservices.com/AmazonS3/latest/API/index.html?RESTObjectGET.html

  Who     Date        Description
  ------  ----------  -------------------------------------
  JKEMP   14.08.2012  Created

  */
  
  get_object_list (
    p_bucket_name             => p_bucket_name,
    p_prefix                  => p_prefix,
    p_max_keys                => p_max_keys,
    p_list                    => l_object_list,
    p_next_continuation_token => l_next_continuation_token --ignored by this function
  );

  return l_object_list;

end get_object_list;


function get_object_tab (p_bucket_name in varchar2,
                         p_prefix in varchar2 := null,
                         p_max_keys in number := null) return t_object_tab pipelined
as
  l_object_list                  t_object_list;
  l_next_continuation_token           varchar2(4000);
begin

  /*

  Purpose:   get objects

  Remarks:

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     19.01.2011  Created

  */

  loop

    get_object_list (
      p_bucket_name             => p_bucket_name,
      p_prefix                  => p_prefix,
      p_max_keys                => p_max_keys,
      p_list                    => l_object_list,
      p_next_continuation_token => l_next_continuation_token
      );
  
    for i in 1 .. l_object_list.count loop
      pipe row (l_object_list(i));
    end loop;
    
    exit when l_next_continuation_token is null;
  
  end loop;

  return;

end get_object_tab;


function get_download_url (p_bucket_name in varchar2,
                           p_key in varchar2,
                           p_expiry_date in date) return varchar2
as
  l_returnvalue                  varchar2(4000);
  l_key                          varchar2(4000) := utl_url.escape (p_key);
  l_epoch                        number;
  l_signature                    varchar2(4000);
begin

  /*

  Purpose:   get download URL

  Remarks:   see http://s3.amazonaws.com/doc/s3-developer-guide/RESTAuthentication.html   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     15.01.2011  Created
  
  */
  
  l_epoch := amazon_aws_auth_pkg.get_epoch (p_expiry_date);
  l_signature := amazon_aws_auth_pkg.get_signature ('GET' || chr(10) || chr(10) || chr(10) || l_epoch || chr(10) || '/' || p_bucket_name || '/' || l_key);
  
  l_returnvalue := get_url (p_bucket_name, l_key)
    || '?AWSAccessKeyId=' || amazon_aws_auth_pkg.get_aws_id
    || '&Expires=' || l_epoch
    || '&Signature=' || wwv_flow_utilities.url_encode2 (l_signature);

  return l_returnvalue;

end get_download_url;


procedure new_object (p_bucket_name in varchar2,
                      p_key in varchar2,
                      p_object in blob,
                      p_content_type in varchar2,
                      p_acl in varchar2 := null)
as

  l_key                          varchar2(4000) := utl_url.escape (p_key);

  l_clob                         clob;
  l_xml                          xmltype;

  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);
  
  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();

begin

  /*

  Purpose:   upload new object

  Remarks:   see  http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     16.01.2011  Created
  
  */

  l_date_str := amazon_aws_auth_pkg.get_date_string;
  
  if p_acl is not null then
    l_auth_str := amazon_aws_auth_pkg.get_auth_string ('PUT' || chr(10) || chr(10) || p_content_type || chr(10) || l_date_str || chr(10) || 'x-amz-acl:' || p_acl || chr(10) || '/' || p_bucket_name || '/' || l_key);
  else
    l_auth_str := amazon_aws_auth_pkg.get_auth_string ('PUT' || chr(10) || chr(10) || p_content_type || chr(10) || l_date_str || chr(10) || '/' || p_bucket_name || '/' || l_key);
  end if;

  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := get_host(p_bucket_name);

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;

  l_header_names.extend;
  l_header_names(4) := 'Content-Type';
  l_header_values.extend;
  l_header_values(4) := nvl(p_content_type, 'application/octet-stream');

  l_header_names.extend;
  l_header_names(5) := 'Content-Length';
  l_header_values.extend;
  l_header_values(5) := dbms_lob.getlength(p_object);
  
  if p_acl is not null then
    l_header_names.extend;
    l_header_names(6) := 'x-amz-acl';
    l_header_values.extend;
    l_header_values(6) := p_acl;
  end if;
  
  l_clob := make_request (get_url (p_bucket_name, l_key), 'PUT', l_header_names, l_header_values, p_object);

  check_for_errors (l_clob);

end new_object;


procedure delete_object (p_bucket_name in varchar2,
                         p_key in varchar2)
as

  l_key                          varchar2(4000) := utl_url.escape (p_key);

  l_clob                         clob;
  l_xml                          xmltype;

  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);
  
  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();

begin

  /*

  Purpose:   delete object

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     18.01.2011  Created
  
  */
  
  l_date_str := amazon_aws_auth_pkg.get_date_string;
  l_auth_str := amazon_aws_auth_pkg.get_auth_string ('DELETE' || chr(10) || chr(10) || chr(10) || l_date_str || chr(10) || '/' || p_bucket_name || '/' || l_key);
  
  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := get_host(p_bucket_name);

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;
  
  l_clob := make_request (get_url(p_bucket_name, l_key), 'DELETE', l_header_names, l_header_values);
  
  check_for_errors (l_clob);

end delete_object;


function get_object (p_bucket_name in varchar2,
                     p_key in varchar2) return blob
as
  l_returnvalue blob;
begin

  /*

  Purpose:   get object

  Remarks:   

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     20.01.2011  Created
  
  */

  l_returnvalue := http_util_pkg.get_blob_from_url (get_download_url (p_bucket_name, p_key, sysdate + 1));

  return l_returnvalue;

end get_object;


procedure delete_bucket (p_bucket_name in varchar2)
as
  l_clob                         clob;
  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);
  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();
  l_endpoint                     varchar2(255);
begin

  /*

  Purpose:   delete bucket

  Remarks:

  Who     Date        Description
  ------  ----------  -------------------------------------
  JKEMP   09.08.2012  Created

  */

  l_date_str := amazon_aws_auth_pkg.get_date_string;
  l_auth_str := amazon_aws_auth_pkg.get_auth_string ('DELETE' || chr(10) || chr(10) || chr(10) || l_date_str || chr(10) || '/' || p_bucket_name || '/');

  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := get_host(p_bucket_name);

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;

  l_clob := make_request (get_url(p_bucket_name), 'DELETE', l_header_names, l_header_values);

  l_endpoint := check_for_redirect (l_clob);
  
  if l_endpoint is not null then
    l_clob := make_request ('http://' || l_endpoint || '/', 'DELETE', l_header_names, l_header_values);
  end if;
  
  check_for_errors (l_clob);

end delete_bucket;


function get_object_acl (p_bucket_name in varchar2,
                         p_key in varchar2) return xmltype
as
                         
  l_clob                         clob;
  l_xml                          xmltype;

  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);

  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();
  
  l_returnvalue                  xmltype;
  
begin

  /*

  Purpose:   get object ACL
  
  Remarks:  get the ACL for an object (private - used by get_object_owner, get_object_grantee_list, get_object_grantee_tab)

  Example return value:
  
  <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Owner>
      <ID>c244a7539c1fc912a06691246c90cb93629690ee4703efac8f08e6ff4cb48ef1</ID>
      <DisplayName>jeffreykemp</DisplayName>
    </Owner>
    <AccessControlList>
      <Grant>
        <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
          <ID>c244a7539c1fc912a06691246c90cb93629690ee4703efac8f08e6ff4cb48ef1</ID>
          <DisplayName>jeffreykemp</DisplayName>
        </Grantee>
        <Permission>FULL_CONTROL</Permission>
      </Grant>
      <Grant>
        <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group">
          <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
        </Grantee>
        <Permission>READ</Permission>
      </Grant>
    </AccessControlList>
  </AccessControlPolicy>

  Who     Date        Description
  ------  ----------  -------------------------------------
  JKEMP   10.08.2012  Created

  */
  
  l_date_str := amazon_aws_auth_pkg.get_date_string;
  l_auth_str := amazon_aws_auth_pkg.get_auth_string ('GET' || chr(10) || chr(10) || chr(10) || l_date_str || chr(10) || '/' || p_bucket_name || '/' || p_key || '?acl');

  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := g_aws_host_s3;

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;

  l_clob := make_request (get_url(p_bucket_name, p_key) || '?acl', 'GET', l_header_names, l_header_values, null);

  if (l_clob is not null) and (length(l_clob) > 0) then

    l_xml := xmltype (l_clob);
    check_for_errors (l_xml);
    l_returnvalue := l_xml;

  end if;

  return l_returnvalue;

end get_object_acl;


function get_object_owner (p_bucket_name in varchar2,
                           p_key in varchar2) return t_owner
as
  l_xml                          xmltype;
  l_returnvalue                  t_owner;
begin

  /*

  Purpose:   get owner for an object

  Remarks:

  Who     Date        Description
  ------  ----------  -------------------------------------
  JKEMP   14.08.2012  Created

  */
  
  l_xml := get_object_acl (p_bucket_name, p_key);
  
  l_returnvalue.user_id := l_xml.extract('//AccessControlPolicy/Owner/ID/text()', g_aws_namespace_s3_full).getStringVal;
  l_returnvalue.user_name := l_xml.extract('//AccessControlPolicy/Owner/DisplayName/text()', g_aws_namespace_s3_full).getStringVal;
  
  return l_returnvalue;
  
end get_object_owner;


function get_object_grantee_list (p_bucket_name in varchar2,
                                  p_key in varchar2) return t_grantee_list
as
  l_xml_namespace_s3_full        constant varchar2(255) := 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"';
  l_xml                          xmltype;
  l_count                        pls_integer := 0;
  l_returnvalue                  t_grantee_list;
begin

  /*

  Purpose:   get grantees for an object

  Remarks:   Each grantee will either be a Canonical User or a Group.
             A Canonical User has an ID and a DisplayName.
             A Group has a URI.
             Permission will be FULL_CONTROL, WRITE, or READ_ACP.

  Who     Date        Description
  ------  ----------  -------------------------------------
  JKEMP   14.08.2012  Created

  */
  
  l_xml := get_object_acl (p_bucket_name, p_key);

  for l_rec in (
    select extractValue(value(t), '*/Grantee/@xsi:type', g_aws_namespace_s3_full || ' ' || l_xml_namespace_s3_full) as grantee_type,
      extractValue(value(t), '*/Grantee/ID', g_aws_namespace_s3_full) as user_id,
      extractValue(value(t), '*/Grantee/DisplayName', g_aws_namespace_s3_full) as user_name,
      extractValue(value(t), '*/Grantee/URI', g_aws_namespace_s3_full) as group_uri,
      extractValue(value(t), '*/Permission', g_aws_namespace_s3_full) as permission
    from table(xmlsequence(l_xml.extract('//AccessControlPolicy/AccessControlList/Grant', g_aws_namespace_s3_full))) t
    ) loop
    l_count := l_count + 1;
    l_returnvalue(l_count).grantee_type := l_rec.grantee_type;
    l_returnvalue(l_count).user_id := l_rec.user_id;
    l_returnvalue(l_count).user_name := l_rec.user_name;
    l_returnvalue(l_count).group_uri := l_rec.group_uri;
    l_returnvalue(l_count).permission := l_rec.permission;
  end loop;
  
  return l_returnvalue;

end get_object_grantee_list;


function get_object_grantee_tab (p_bucket_name in varchar2,
                                 p_key in varchar2) return t_grantee_tab pipelined
as
  l_grantee_list  t_grantee_list;
begin

  /*

  Purpose:   get grantees for an object

  Remarks:

  Who     Date        Description
  ------  ----------  -------------------------------------
  JKEMP   14.08.2012  Created

  */
  
  l_grantee_list := get_object_grantee_list (p_bucket_name, p_key);

  for i in 1 .. l_grantee_list.count loop
    pipe row (l_grantee_list(i));
  end loop;

  return;
  
end get_object_grantee_tab;


procedure set_object_acl (p_bucket_name in varchar2,
                          p_key in varchar2,
                          p_acl in varchar2)
as
  l_key                          varchar2(4000) := utl_url.escape (p_key);
  l_clob                         clob;
  l_xml                          xmltype;
  l_date_str                     varchar2(255);
  l_auth_str                     varchar2(255);
  l_header_names                 t_str_array := t_str_array();
  l_header_values                t_str_array := t_str_array();
begin

  /*

  Purpose:   modify the access control list (owner and grantees) for an object

  Remarks:   see http://code.google.com/p/plsql-utils/issues/detail?id=17

  Who     Date        Description
  ------  ----------  -------------------------------------
  JKEMP   22.09.2012  Created

  */

  l_date_str := amazon_aws_auth_pkg.get_date_string;
  l_auth_str := amazon_aws_auth_pkg.get_auth_string ('PUT' || chr(10) || chr(10) || chr(10) || l_date_str || chr(10) || 'x-amz-acl:' || p_acl || chr(10) || '/' || p_bucket_name || '/' || l_key || '?acl');

  l_header_names.extend;
  l_header_names(1) := 'Host';
  l_header_values.extend;
  l_header_values(1) := get_host(p_bucket_name);

  l_header_names.extend;
  l_header_names(2) := 'Date';
  l_header_values.extend;
  l_header_values(2) := l_date_str;

  l_header_names.extend;
  l_header_names(3) := 'Authorization';
  l_header_values.extend;
  l_header_values(3) := l_auth_str;

  l_header_names.extend;
  l_header_names(4) := 'x-amz-acl';
  l_header_values.extend;
  l_header_values(4) := p_acl;

  l_clob := make_request (get_url(p_bucket_name, l_key) || '?acl', 'PUT', l_header_names, l_header_values);

  check_for_errors (l_clob);

end set_object_acl;


end amazon_aws_s3_pkg;
/

