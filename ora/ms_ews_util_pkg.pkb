create or replace package body ms_ews_util_pkg
as
 
  /*
 
  Purpose:      Package handles Microsoft Exchange Web Services (EWS)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
 
  */
  
  g_namespace_soap               constant varchar2(2000) := 'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"';
  g_namespace_messages           constant varchar2(2000) := 'xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages"';
  g_namespace_types              constant varchar2(2000) := 'xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types"';

  g_soap_action_prefix           constant varchar2(2000) := 'http://schemas.microsoft.com/exchange/services/2006/messages/';

  g_soap_version                 constant varchar2(10) := '1.1';
  
  g_ntlm_auth_header_name        constant varchar2(30) := 'Authorization';
  
  g_max_rows                     constant number := 100;
  
  g_service_url                  varchar2(2000);
  g_username                     varchar2(2000);
  g_password                     varchar2(2000);
  g_wallet_path                  varchar2(2000);
  g_wallet_password              varchar2(2000);
 
 
procedure init (p_service_url in varchar2,
                p_username in varchar2,
                p_password in varchar2,
                p_wallet_path in varchar2 := null,
                p_wallet_password in varchar2 := null) 
as
begin
 
  /*
 
  Purpose:      initialize settings
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
 
  */
 
  g_service_url := p_service_url;
  g_username := p_username;
  g_password := p_password;
  g_wallet_path := p_wallet_path;
  g_wallet_password := p_wallet_password;
 
end init;
 

procedure raise_error (p_error_message in varchar2)
as
begin

  /*
 
  Purpose:      raise error
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */

  raise_application_error (-20000, 'EWS for PL/SQL: ' || p_error_message);

end raise_error;


procedure assert_init 
as
begin
 
  /*
 
  Purpose:      assert that initialization has been called
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */
 
  if g_service_url is null then
    raise_error ('Web Service URL not specified. Please call .init() at least once per database session.');
  end if;

  if g_username is null then
    raise_error ('Username not specified. Please call .init() at least once per database session.');
  end if;

  if g_password is null then
    raise_error ('Password not specified. Please call .init() at least once per database session.');
  end if;

  if lower(g_service_url) like 'https%' then

    if g_wallet_path is null then
      raise_error ('Oracle Wallet path not specified. When using HTTPS you must reference an Oracle Wallet.');
    end if;

    if g_wallet_password is null then
      raise_error ('Oracle Wallet password not specified. When using HTTPS you must reference an Oracle Wallet.');
    end if;

  end if;
 
end assert_init;


function get_date (p_date_str in varchar2) return date
as
  l_returnvalue date;
begin

  /*

  Purpose:    get date 

  Remarks:    TODO: the time zone part, if any, is currently ignored
              

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.04.2012  Created

  */
  
  begin
    l_returnvalue := to_date(substr(p_date_str,1,19), 'YYYY-MM-DD"T"HH24:MI:SS');
  exception
    when others then
      l_returnvalue := null;
  end;
  
  return l_returnvalue;

end get_date;


function get_date_str (p_date in date) return varchar2
as
  l_returnvalue varchar2(20);
begin

  /*

  Purpose:    get date string

  Remarks:                  

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.04.2012  Created

  */
  
  l_returnvalue := to_char(p_date, 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
  
  return l_returnvalue;

end get_date_str;


function get_bool_str (p_boolean in boolean) return varchar2
as
  l_returnvalue varchar2(10);
begin

  /*

  Purpose:    get boolean string

  Remarks:    null values are returned as "false"              

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     21.04.2012  Created

  */
  
  if p_boolean then
    l_returnvalue := 'true';
  else
    l_returnvalue := 'false';
  end if;
  
  return l_returnvalue;

end get_bool_str;


function is_distinguished_folder_id (p_folder_id in varchar2) return boolean
as
  l_returnvalue boolean;
begin

  /*
 
  Purpose:      return true if specified folder is "distinguished"
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */
  
  l_returnvalue := p_folder_id in (g_folder_id_root,
                                   g_folder_id_message_root,
                                   g_folder_id_inbox,
                                   g_folder_id_sent_items,
                                   g_folder_id_deleted_items,
                                   g_folder_id_outbox,
                                   g_folder_id_junk_email,
                                   g_folder_id_drafts,
                                   g_folder_id_calendar);

  return l_returnvalue;


end is_distinguished_folder_id;


procedure check_for_errors (p_xml in xmltype)
as
  l_response_code varchar2(255);
  l_message       varchar2(2000);
begin

  /*
 
  Purpose:      check for errors, and raise exception if error found (using extracted error message)
 
  Remarks:      the ResolveNames operation actually returns an error if none or many matches are found, see http://msdn.microsoft.com/en-us/library/aa563518(v=exchg.140).aspx
                those errors are ignored here since we want to return a list of matches to the caller instead of raising an exception
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */

  -- TODO: handle soap protocol error (?)
  -- sample error message:
  -- <?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><s:Fault><faultcode xmlns:a="http://schemas.microsoft.com/exchange/services/2006/types">a:ErrorSchemaValidation</faultcode><faultstring xml:lang="nb-NO">The request failed schema validation: Could not find schema information for the element 'FindFolder'.</faultstring><detail><e:ResponseCode xmlns:e="http://schemas.microsoft.com/exchange/services/2006/errors">ErrorSchemaValidation</e:ResponseCode><e:Message xmlns:e="http://schemas.microsoft.com/exchange/services/2006/errors">The request failed schema validation.</e:Message><t:MessageXml xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types"><t:LineNumber>4</t:LineNumber><t:LinePosition>10</t:LinePosition><t:Violation>Could not find schema information for the element 'FindFolder'.</t:Violation></t:MessageXml></detail></s:Fault></s:Body></s:Envelope>

  
  l_response_code := flex_ws_api.parse_xml (p_xml, '//*/m:ResponseCode[1]/text()', g_namespace_messages);
  
  if l_response_code not in ('NoError', 'ErrorNameResolutionNoResults', 'ErrorNameResolutionMultipleResults') then
    l_message := flex_ws_api.parse_xml (p_xml, '//*/m:MessageText[1]/text()', g_namespace_messages);
    raise_error (l_response_code || ': ' || l_message);
  end if;
  

end check_for_errors;


function make_request (p_soap_action in varchar2,
                       p_soap_envelope in clob) return xmltype
as
  l_ntlm_auth_str                varchar2(2000);
  l_returnvalue                  xmltype;
begin

  /*
 
  Purpose:      make SOAP request, and return response
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */

  assert_init;

  -- perform the initial request to set up a persistent, authenticated connection
  l_ntlm_auth_str := ntlm_http_pkg.begin_request (g_service_url, g_username, g_password, g_wallet_path, g_wallet_password);

  -- use latest version of flex_ws_api or apex_web_service (Apex 4.1 +)
  flex_ws_api.g_request_headers(1).name := g_ntlm_auth_header_name;
  flex_ws_api.g_request_headers(1).value := l_ntlm_auth_str;
  l_returnvalue := flex_ws_api.make_request(g_service_url, p_soap_action, g_soap_version, p_soap_envelope, p_wallet_path => g_wallet_path, p_wallet_pwd => g_wallet_password);

  -- this will close the persistent connection
  ntlm_http_pkg.end_request;

  debug_pkg.print(p_xml => l_returnvalue);

  check_for_errors (l_returnvalue);
  
  return l_returnvalue;

end make_request;
 

function find_folders_as_list (p_parent_folder_id in varchar2 := null) return t_folder_list
as
  l_count                        pls_integer := 0;
  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'FindFolder';
  l_xml                          xmltype;
  l_returnvalue                  t_folder_list;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:FindFolder Traversal="Shallow">
          <m:FolderShape>
            <t:BaseShape>Default</t:BaseShape>
          </m:FolderShape>
          <m:ParentFolderIds>' ||
            case
                when is_distinguished_folder_id (nvl(p_parent_folder_id, g_folder_id_message_root)) then '<t:DistinguishedFolderId Id="' || nvl(p_parent_folder_id, g_folder_id_message_root) || '"/>'
                else '<t:FolderId Id="' || p_parent_folder_id || '"/>'
              end ||
          '</m:ParentFolderIds>
        </m:FindFolder>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin
 
  /*
 
  Purpose:      find folders
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);
  
  for l_rec in (
    select extractValue(value(t), '*/t:FolderId/@Id', g_namespace_types) as folder_id,
      extractValue(value(t), '*/t:DisplayName', g_namespace_types) as display_name,
      extractValue(value(t), '*/t:TotalCount', g_namespace_types) as total_count,
      extractValue(value(t), '*/t:ChildFolderCount', g_namespace_types) as child_folder_count,
      extractValue(value(t), '*/t:UnreadCount', g_namespace_types) as unread_count
    from table(xmlsequence(l_xml.extract('//t:Folders/t:Folder', g_namespace_types))) t
    )
  loop
    l_count := l_count + 1;
    l_returnvalue(l_count).sequence_number := l_count;
    l_returnvalue(l_count).folder_id := l_rec.folder_id;
    l_returnvalue(l_count).display_name := l_rec.display_name;
    l_returnvalue(l_count).total_count := to_number(l_rec.total_count);
    l_returnvalue(l_count).child_folder_count := to_number(l_rec.child_folder_count);
    l_returnvalue(l_count).unread_count := to_number(l_rec.unread_count);
  end loop;
 
  return l_returnvalue;
 
end find_folders_as_list;
 
 
function find_folders (p_parent_folder_id in varchar2 := null) return t_folder_tab pipelined
as
  l_folders t_folder_list;
begin
 
  /*
 
  Purpose:      find folders
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */
 
  l_folders := find_folders_as_list (p_parent_folder_id);
  
  for i in 1 .. l_folders.count loop
    pipe row (l_folders(i));
  end loop;

  return;
 
end find_folders;


function get_folder_id_by_name (p_folder_name in varchar2,
                                p_parent_folder_id in varchar2 := null) return varchar2
as
  l_folders                      t_folder_list;
  l_returnvalue                  varchar2(2000);
begin

  /*
 
  Purpose:      get folder id by name
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */
  
  l_folders := find_folders_as_list (p_parent_folder_id);
  
  for i in 1 .. l_folders.count loop
    if l_folders(i).display_name = p_folder_name then
      l_returnvalue := l_folders(i).folder_id;
      exit;
    end if;
  end loop;

  return l_returnvalue;

end get_folder_id_by_name;


function get_folder (p_folder_id in varchar2) return t_folder
as
  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'GetFolder';
  l_xml                          xmltype;
  l_returnvalue                  t_folder;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     02.05.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:GetFolder>
          <m:FolderShape>
            <t:BaseShape>Default</t:BaseShape>
          </m:FolderShape>
          <m:FolderIds>' ||
            case
                when is_distinguished_folder_id (p_folder_id) then '<t:DistinguishedFolderId Id="' || p_folder_id || '"/>'
                else '<t:FolderId Id="' || p_folder_id || '"/>'
              end ||
          '</m:FolderIds>
        </m:GetFolder>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin
 
  /*
 
  Purpose:      get folder
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.05.2012  Created
 
  */

  l_xml := make_request (l_soap_action, get_request_envelope);

  l_returnvalue.sequence_number := 1;
  l_returnvalue.folder_id := flex_ws_api.parse_xml(l_xml, '//*/t:FolderId/@Id', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.display_name := flex_ws_api.parse_xml(l_xml, '//*/t:DisplayName/text()', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.total_count := to_number(flex_ws_api.parse_xml(l_xml, '//*/t:TotalCount/text()', g_namespace_messages || ' ' || g_namespace_types));
  l_returnvalue.child_folder_count := to_number(flex_ws_api.parse_xml(l_xml, '//*/t:ChildFolderCount/text()', g_namespace_messages || ' ' || g_namespace_types));
  l_returnvalue.unread_count := to_number(flex_ws_api.parse_xml(l_xml, '//*/t:UnreadCount/text()', g_namespace_messages || ' ' || g_namespace_types));

  return l_returnvalue;

end get_folder;


function find_items_as_list (p_folder_id in varchar2 := null,
                             p_search_string in varchar2 := null,
                             p_search_from_date in date := null,
                             p_search_to_date in date := null,
                             p_max_rows in number := null,
                             p_offset in number := null,
                             p_username in varchar2 := null) return t_item_list
as
  l_item_type                    varchar2(30);
  l_count                        pls_integer := 0;
  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'FindItem';
  l_xml                          xmltype;
  l_returnvalue                  t_item_list;
  
  function get_restriction return varchar2
  as
    l_from_date_field  varchar2(255);
    l_to_date_field    varchar2(255);
    l_returnvalue      varchar2(32000);
  begin
  
    if l_item_type = 'CalendarItem' then
      l_from_date_field := 'calendar:Start';
      l_to_date_field := 'calendar:End';
    else
      l_from_date_field := 'item:DateTimeCreated';
      l_to_date_field := 'item:DateTimeCreated';
    end if;
  
    if p_search_string is not null then
      l_returnvalue := '<t:Or>
         <t:Contains ContainmentComparison="IgnoreCase" ContainmentMode="Substring">
            <t:FieldURI FieldURI="item:Subject" />
            <t:Constant Value="' || p_search_string || '" />
         </t:Contains>
         <t:Contains ContainmentComparison="IgnoreCase" ContainmentMode="Substring">
            <t:FieldURI FieldURI="item:Body" />
            <t:Constant Value="' || p_search_string || '" />
         </t:Contains>
       </t:Or>';
    end if;
    
    if p_search_from_date is not null then
      l_returnvalue := l_returnvalue || '<t:IsGreaterThanOrEqualTo>
                        <t:FieldURI FieldURI="' || l_from_date_field || '"/>
                        <t:FieldURIOrConstant>
                            <t:Constant Value="' || get_date_str(p_search_from_date) || '" />
                        </t:FieldURIOrConstant>
                    </t:IsGreaterThanOrEqualTo>';
    end if;

    if p_search_to_date is not null then
      l_returnvalue := l_returnvalue || '<t:IsLessThanOrEqualTo>
                        <t:FieldURI FieldURI="' || l_to_date_field || '"/>
                        <t:FieldURIOrConstant>
                            <t:Constant Value="' || get_date_str(p_search_to_date) || '" />
                        </t:FieldURIOrConstant>
                    </t:IsLessThanOrEqualTo>';
    end if;
    
    if p_search_from_date is not null or p_search_to_date is not null then
      l_returnvalue := '<t:And>' || l_returnvalue || '</t:And>';
    end if;
    
    if l_returnvalue is not null then
      l_returnvalue := '<m:Restriction>' || l_returnvalue || '</m:Restriction>';
    end if;
  
  
    return l_returnvalue;

  end get_restriction;
  

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      for handling search in the mailbox of another user using the p_username parameter, see http://www.leederbyshire.com/Articles/EWS-FindItem-Other-Mailbox-Exchange-2007.asp 
                  TODO: check if this can also be used for specific (non-distinguished) folders
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:FindItem Traversal="Shallow">
          <m:ItemShape>
            <t:BaseShape>Default</t:BaseShape>
            <t:AdditionalProperties>
              <t:FieldURI FieldURI="item:ItemClass"/>
              <t:FieldURI FieldURI="item:DateTimeReceived"/>
              <t:FieldURI FieldURI="calendar:Start"/>
              <t:FieldURI FieldURI="calendar:End"/>
            </t:AdditionalProperties>
          </m:ItemShape>
          <m:IndexedPageItemView MaxEntriesReturned="' || least(nvl(p_max_rows,10), g_max_rows) || '" BasePoint="Beginning" Offset="' || nvl(p_offset,0) || '"/>'
          || get_restriction ||
          '<m:ParentFolderIds>' ||
            case
                when is_distinguished_folder_id (nvl(p_folder_id, g_folder_id_inbox)) then '<t:DistinguishedFolderId Id="' || nvl(p_folder_id, g_folder_id_inbox) || '">' || case when p_username is not null then '<t:Mailbox><t:EmailAddress>' || p_username || '</t:EmailAddress></t:Mailbox>' end || '</t:DistinguishedFolderId>'
                else '<t:FolderId Id="' || p_folder_id || '"/>'
              end ||
          '</m:ParentFolderIds>
        </m:FindItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin
 
  /*
 
  Purpose:      find items
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
 
  */

  if p_folder_id = g_folder_id_calendar then
    l_item_type := 'CalendarItem';
  else
    l_item_type := 'Message';
  end if;
  
  l_xml := make_request (l_soap_action, get_request_envelope);

  for l_rec in (
    select extractValue(value(t), '*/t:ItemId/@Id', g_namespace_types) as item_id,
      extractValue(value(t), '*/t:ItemId/@ChangeKey', g_namespace_types) as change_key,
      extractValue(value(t), '*/t:ParentFolderId', g_namespace_types) as parent_folder_id,
      extractValue(value(t), '*/t:Size', g_namespace_types) as item_size,
      extractValue(value(t), '*/t:ItemClass', g_namespace_types) as item_class,
      extractValue(value(t), '*/t:Subject', g_namespace_types) as subject,
      extractValue(value(t), '*/t:Sensitivity', g_namespace_types) as sensitivity,
      extractValue(value(t), '*/t:DateTimeCreated', g_namespace_types) as datetime_created,
      extractValue(value(t), '*/t:DateTimeSent', g_namespace_types) as datetime_sent,
      extractValue(value(t), '*/t:DateTimeReceived', g_namespace_types) as datetime_received,
      extractValue(value(t), '*/t:HasAttachments', g_namespace_types) as has_attachments,
      extractValue(value(t), '*/t:From/t:Mailbox/t:Name', g_namespace_types) as from_mailbox_name,
      extractValue(value(t), '*/t:IsRead', g_namespace_types) as is_read,
      extractValue(value(t), '*/t:Location', g_namespace_types) as location,
      extractValue(value(t), '*/t:Organizer/t:Mailbox/t:Name', g_namespace_types) as organizer_mailbox_name,
      extractValue(value(t), '*/t:Start', g_namespace_types) as start_date,
      extractValue(value(t), '*/t:End', g_namespace_types) as end_date
    from table(xmlsequence(l_xml.extract('//t:Items/t:' || l_item_type, g_namespace_types))) t
    )
  loop
    l_count := l_count + 1;
    -- general Item
    l_returnvalue(l_count).sequence_number := l_count;
    l_returnvalue(l_count).item_id := l_rec.item_id;
    l_returnvalue(l_count).change_key := l_rec.change_key;
    l_returnvalue(l_count).parent_folder_id := l_rec.parent_folder_id;
    l_returnvalue(l_count).item_size := to_number(l_rec.item_size);
    l_returnvalue(l_count).item_class := l_rec.item_class;
    l_returnvalue(l_count).subject := l_rec.subject;
    l_returnvalue(l_count).sensitivity := l_rec.sensitivity;
    l_returnvalue(l_count).datetime_created := get_date(l_rec.datetime_created);
    l_returnvalue(l_count).datetime_sent := get_date(l_rec.datetime_sent);
    l_returnvalue(l_count).datetime_received := get_date(l_rec.datetime_received);
    l_returnvalue(l_count).has_attachments := l_rec.has_attachments;
    -- mail Message
    l_returnvalue(l_count).from_mailbox_name := l_rec.from_mailbox_name;
    l_returnvalue(l_count).is_read := l_rec.is_read;
    -- CalendarItem
    l_returnvalue(l_count).location := l_rec.location;
    l_returnvalue(l_count).organizer_mailbox_name := l_rec.organizer_mailbox_name;
    l_returnvalue(l_count).start_date := get_date(l_rec.start_date);
    l_returnvalue(l_count).end_date := get_date(l_rec.end_date);
  end loop;
 
  return l_returnvalue;
 
end find_items_as_list;
 
 
function find_items (p_folder_id in varchar2 := null,
                     p_search_string in varchar2 := null,
                     p_search_from_date in date := null,
                     p_search_to_date in date := null,
                     p_max_rows in number := null,
                     p_offset in number := null,
                     p_username in varchar2 := null) return t_item_tab pipelined
as
  l_items t_item_list;
begin
 
  /*
 
  Purpose:      find items
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
 
  */
 
  l_items := find_items_as_list (p_folder_id, p_search_string, p_search_from_date, p_search_to_date, p_max_rows, p_offset, p_username);
  
  for i in 1 .. l_items.count loop
    pipe row (l_items(i));
  end loop;

  return;
 
end find_items;


function get_item (p_item_id in varchar2,
                   p_body_type in varchar2 := null,
                   p_include_mime_content in boolean := false) return t_item
as
  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'GetItem';
  l_xml                          xmltype;
  l_returnvalue                  t_item;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:GetItem>
          <m:ItemShape>
            <t:BaseShape>Default</t:BaseShape>
            <t:IncludeMimeContent>' || get_bool_str (p_include_mime_content) || '</t:IncludeMimeContent>
            <t:BodyType>' || nvl(p_body_type, g_body_type_best) || '</t:BodyType>
            <t:AdditionalProperties>
              <t:FieldURI FieldURI="item:ItemClass"/>
              <t:FieldURI FieldURI="item:DateTimeReceived"/>
              <t:FieldURI FieldURI="item:Body"/>
              <t:FieldURI FieldURI="item:Attachments"/>
            </t:AdditionalProperties>
          </m:ItemShape>
          <m:ItemIds>
            <t:ItemId Id="' || p_item_id || '"/>
          </m:ItemIds>
        </m:GetItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin
 
  /*
 
  Purpose:      get item
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
 
  */

  l_xml := make_request (l_soap_action, get_request_envelope);

  l_returnvalue.item_class := flex_ws_api.parse_xml(l_xml, '//*/t:ItemClass/text()', g_namespace_messages || ' ' || g_namespace_types);
  
  -- general Item info
  l_returnvalue.sequence_number := 1;
  l_returnvalue.item_id := flex_ws_api.parse_xml(l_xml, '//*/t:ItemId/@Id', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.change_key := flex_ws_api.parse_xml(l_xml, '//*/t:ItemId/@ChangeKey', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.item_size := to_number(flex_ws_api.parse_xml(l_xml, '//*/t:Size/text()', g_namespace_messages || ' ' || g_namespace_types));
  
  l_returnvalue.subject := flex_ws_api.parse_xml(l_xml, '//*/t:Subject/text()', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.sensitivity := flex_ws_api.parse_xml(l_xml, '//*/t:Sensitivity/text()', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.datetime_created := get_date(flex_ws_api.parse_xml(l_xml, '//*/t:DateTimeCreated/text()', g_namespace_messages || ' ' || g_namespace_types));
  l_returnvalue.datetime_sent := get_date(flex_ws_api.parse_xml(l_xml, '//*/t:DateTimeSent/text()', g_namespace_messages || ' ' || g_namespace_types));
  l_returnvalue.datetime_received := get_date(flex_ws_api.parse_xml(l_xml, '//*/t:DateTimeReceived/text()', g_namespace_messages || ' ' || g_namespace_types));
  l_returnvalue.has_attachments := flex_ws_api.parse_xml(l_xml, '//*/t:HasAttachments/text()', g_namespace_messages || ' ' || g_namespace_types);

  l_returnvalue.body := flex_ws_api.parse_xml_clob (l_xml, '//*/t:Body/text()', g_namespace_messages || ' ' || g_namespace_types);

  if p_include_mime_content then
    l_returnvalue.mime_content := flex_ws_api.parse_xml_clob (l_xml, '//*/t:MimeContent/text()', g_namespace_messages || ' ' || g_namespace_types);
  end if;

  if l_returnvalue.item_class = g_item_class_message then

    -- mail Message
    l_returnvalue.from_mailbox_name := flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:Message/t:From/t:Mailbox/t:Name/text()', g_namespace_messages || ' ' || g_namespace_types);
    l_returnvalue.is_read := flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:Message/t:IsRead/text()', g_namespace_messages || ' ' || g_namespace_types);

  elsif l_returnvalue.item_class = g_item_class_appointment then

    -- CalendarItem
    l_returnvalue.organizer_mailbox_name := flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:CalendarItem/t:Organizer/t:Mailbox/t:Name/text()', g_namespace_messages || ' ' || g_namespace_types);
    l_returnvalue.location := flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:CalendarItem/t:Location/text()', g_namespace_messages || ' ' || g_namespace_types);
    l_returnvalue.start_date := get_date(flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:CalendarItem/t:Start/text()', g_namespace_messages || ' ' || g_namespace_types));
    l_returnvalue.end_date := get_date(flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:CalendarItem/t:End/text()', g_namespace_messages || ' ' || g_namespace_types));
    
  end if;
 
  return l_returnvalue;
 
end get_item;


procedure move_item (p_item_id in varchar2,
                     p_folder_id in varchar2)
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'MoveItem';
  l_xml                          xmltype;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa565781(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:MoveItem>
      <m:ToFolderId>' ||
          case
            when is_distinguished_folder_id (p_folder_id) then '<t:DistinguishedFolderId Id="' || p_folder_id || '"/>'
            else '<t:FolderId Id="' || p_folder_id || '"/>'
          end ||
      '</m:ToFolderId>
      <m:ItemIds>
        <t:ItemId Id="' || p_item_id || '"/>
      </m:ItemIds>
    </m:MoveItem>
  </soap:Body>
</soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      move item
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);

end move_item;


procedure copy_item (p_item_id in varchar2,
                     p_folder_id in varchar2)
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'CopyItem';
  l_xml                          xmltype;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa565012(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     02.05.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:CopyItem>
      <m:ToFolderId>' ||
          case
            when is_distinguished_folder_id (p_folder_id) then '<t:DistinguishedFolderId Id="' || p_folder_id || '"/>'
            else '<t:FolderId Id="' || p_folder_id || '"/>'
          end ||
      '</m:ToFolderId>
      <m:ItemIds>
        <t:ItemId Id="' || p_item_id || '"/>
      </m:ItemIds>
    </m:CopyItem>
  </soap:Body>
</soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      copy item
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.05.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);

end copy_item;


procedure delete_item (p_item_id in varchar2,
                       p_delete_type in varchar2 := null)
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'DeleteItem';
  l_xml                          xmltype;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa580484(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:DeleteItem DeleteType="' || nvl(p_delete_type, g_delete_type_move_to_d_items) || '">
      <m:ItemIds>
        <t:ItemId Id="' || p_item_id || '"/>
      </m:ItemIds>
    </m:DeleteItem>
  </soap:Body>
</soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      delete item
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);

end delete_item;

 
procedure send_item (p_item_id in varchar2,
                     p_save_item_to_folder in boolean := true)
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'SendItem';
  l_xml                          xmltype;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa580238(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     02.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:SendItem SaveItemToFolder="' || get_bool_str(p_save_item_to_folder) || '">
          <m:ItemIds>
            <t:ItemId Id="' || p_item_id || '"/>
          </m:ItemIds>
        </m:SendItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      send item
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.05.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);

end send_item;


function create_calendar_item (p_item in t_item,
                               p_send_meeting_invitations in varchar2 := null,
                               p_required_attendees in t_str_array := null) return varchar2
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'CreateItem';
  l_xml                          xmltype;
  l_returnvalue                  varchar2(2000);
  
  
  function get_required_attendees return clob
  as
    l_returnvalue clob := ' ';
  begin
  
    if p_required_attendees.count > 0 then
    
      for i in p_required_attendees.first .. p_required_attendees.last loop
        l_returnvalue := l_returnvalue || '<t:Attendee><t:Mailbox><t:EmailAddress>' || p_required_attendees(i) || '</t:EmailAddress></t:Mailbox></t:Attendee>';
      end loop;
      
      l_returnvalue := '<t:RequiredAttendees>' || l_returnvalue || '</t:RequiredAttendees>';
      
    end if;
  
    return l_returnvalue;
  
  end get_required_attendees;
  

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa564690(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     02.05.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:CreateItem SendMeetingInvitations="' || nvl(p_send_meeting_invitations, g_meeting_inv_send_to_all_save) || '">
          <m:SavedItemFolderId>' ||
          case
            when is_distinguished_folder_id (nvl(p_item.parent_folder_id, g_folder_id_calendar)) then '<t:DistinguishedFolderId Id="' || nvl(p_item.parent_folder_id, g_folder_id_calendar) || '"/>'
            else '<t:FolderId Id="' || p_item.parent_folder_id || '"/>'
          end
          || '</m:SavedItemFolderId>
          <m:Items>
            <t:CalendarItem>
              <t:Subject>' || dbms_xmlgen.convert(p_item.subject, dbms_xmlgen.entity_encode) || '</t:Subject>
              <t:Body BodyType="Text">' || dbms_xmlgen.convert(p_item.body, dbms_xmlgen.entity_encode) || '</t:Body>
              <t:ReminderIsSet>' || nvl(p_item.reminder_is_set, g_false) || '</t:ReminderIsSet>
              <t:ReminderMinutesBeforeStart>' || nvl(p_item.reminder_minutes_before_start,0) || '</t:ReminderMinutesBeforeStart>
              <t:Start>' || get_date_str(p_item.start_date) || '</t:Start>
              <t:End>' || get_date_str(nvl(p_item.end_date, p_item.start_date)) || '</t:End>
              <t:IsAllDayEvent>' || nvl(p_item.is_all_day_event, g_false) || '</t:IsAllDayEvent>
              <t:LegacyFreeBusyStatus>' || nvl(p_item.legacy_free_busy_status, g_free_busy_status_busy) || '</t:LegacyFreeBusyStatus>
              <t:Location>' || dbms_xmlgen.convert(p_item.location, dbms_xmlgen.entity_encode) || '</t:Location>'
              || get_required_attendees ||  
            '</t:CalendarItem>
          </m:Items>
        </m:CreateItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      create calendar item
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.05.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);
  
  -- TODO: verify that ID is returned/parsed...
  l_returnvalue := flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:CalendarItem/t:ItemId/@Id', g_namespace_messages || ' ' || g_namespace_types);
  
  return l_returnvalue;

end create_calendar_item;


function create_task_item (p_item in t_item) return varchar2
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'CreateItem';
  l_xml                          xmltype;
  l_returnvalue                  varchar2(2000);
  
  
  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa563439(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     02.05.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:CreateItem>
          <m:Items>
            <t:Task>
              <t:Subject>' || dbms_xmlgen.convert(p_item.subject, dbms_xmlgen.entity_encode) || '</t:Subject>
              <t:Body BodyType="Text">' || dbms_xmlgen.convert(p_item.body, dbms_xmlgen.entity_encode) || '</t:Body>
              <t:DueDate>' || get_date_str(p_item.due_date) || '</t:DueDate>
              <t:Status>' || nvl(p_item.status, g_task_status_not_started) || '</t:Status>
            </t:Task>
          </m:Items>
        </m:CreateItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      create task item
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.05.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);
  
  -- TODO: verify that ID is returned/parsed...
  l_returnvalue := flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:Task/t:ItemId/@Id', g_namespace_messages || ' ' || g_namespace_types);
  
  return l_returnvalue;

end create_task_item;


function create_message_item (p_item in t_item,
                              p_message_disposition in varchar2 := null,
                              p_to_recipients in t_str_array := null) return varchar2
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'CreateItem';
  l_xml                          xmltype;
  l_returnvalue                  varchar2(2000);
  
  
  function get_to_recipients return clob
  as
    l_returnvalue clob := ' ';
  begin
  
    if p_to_recipients.count > 0 then
    
      for i in p_to_recipients.first .. p_to_recipients.last loop
        l_returnvalue := l_returnvalue || '<t:Mailbox><t:EmailAddress>' || p_to_recipients(i) || '</t:EmailAddress></t:Mailbox>';
      end loop;
      
      l_returnvalue := '<t:ToRecipients>' || l_returnvalue || '</t:ToRecipients>'; 
      
    end if;
  
    return l_returnvalue;
  
  end get_to_recipients;


  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa563439(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     02.05.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:CreateItem MessageDisposition="' || nvl(p_message_disposition, g_message_disp_send_and_save) || '">
          <m:SavedItemFolderId>' ||
          case
            when is_distinguished_folder_id (nvl(p_item.parent_folder_id, g_folder_id_drafts)) then '<t:DistinguishedFolderId Id="' || nvl(p_item.parent_folder_id, g_folder_id_calendar) || '"/>'
            else '<t:FolderId Id="' || p_item.parent_folder_id || '"/>'
          end
          || '</m:SavedItemFolderId>
          <m:Items>
            <t:Message>
              <t:ItemClass>' || g_item_class_message || '</t:ItemClass>
              <t:Subject>' || dbms_xmlgen.convert(p_item.subject, dbms_xmlgen.entity_encode) || '</t:Subject>
              <t:Body BodyType="Text">' || dbms_xmlgen.convert(p_item.body, dbms_xmlgen.entity_encode) || '</t:Body>'
              || get_to_recipients || 
              '<t:IsRead>' || nvl(p_item.is_read, g_false) || '</t:IsRead>
            </t:Message>
          </m:Items>
        </m:CreateItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      create task item
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.05.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);
  
  -- TODO: verify that ID is returned/parsed...
  l_returnvalue := flex_ws_api.parse_xml(l_xml, '//*/m:Items/t:Message/t:ItemId/@Id', g_namespace_messages || ' ' || g_namespace_types);
  
  return l_returnvalue;

end create_message_item;


procedure update_item_is_read (p_item_id in varchar2,
                               p_change_key in varchar2,
                               p_is_read in boolean)
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'UpdateItem';
  l_xml                          xmltype;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa581084(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     02.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:UpdateItem ConflictResolution="AutoResolve" MessageDisposition="SaveOnly">
          <m:ItemChanges>
            <t:ItemChange>
              <t:ItemId Id="' || p_item_id || '" ChangeKey="' || p_change_key || '" />
              <t:Updates>
                <t:SetItemField>
                  <t:FieldURI FieldURI="message:IsRead" />
                  <t:Message>
                    <t:IsRead>' || get_bool_str (p_is_read) || '</t:IsRead>
                  </t:Message>
                </t:SetItemField>
              </t:Updates>
            </t:ItemChange>
          </m:ItemChanges>
        </m:UpdateItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      update item
 
  Remarks:      this is a an example of updating a single property
                in the future, the API may be expanded with a generic update_item() procedure, or additional update procedures for specific item properties
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.05.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);

end update_item_is_read;


function get_file_attachments_as_list (p_item_id in varchar2,
                                       p_include_content in boolean := false) return t_file_attachment_list
as

  l_count                        pls_integer := 0;
  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'GetItem';
  l_xml                          xmltype;
  l_returnvalue                  t_file_attachment_list;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:GetItem>
          <m:ItemShape>
            <t:BaseShape>IdOnly</t:BaseShape>
            <t:AdditionalProperties>
              <t:FieldURI FieldURI="item:Attachments"/>
            </t:AdditionalProperties>
          </m:ItemShape>
          <m:ItemIds>
            <t:ItemId Id="' || p_item_id || '"/>
          </m:ItemIds>
        </m:GetItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;


begin


  /*
 
  Purpose:      get item file attachments
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
 
  */

  l_xml := make_request (l_soap_action, get_request_envelope);

  for l_rec in (
    select extractValue(value(t), '*/t:AttachmentId/@Id', g_namespace_messages || ' ' || g_namespace_types) as attachment_id,
      extractValue(value(t), '*/t:Name', g_namespace_messages || ' ' || g_namespace_types) as name,
      extractValue(value(t), '*/t:ContentType', g_namespace_messages || ' ' || g_namespace_types) as content_type,
      extractValue(value(t), '*/t:ContentId', g_namespace_messages || ' ' || g_namespace_types) as content_id
    from table(xmlsequence(l_xml.extract('//m:Items/t:Message/t:Attachments/t:FileAttachment', g_namespace_messages || ' ' || g_namespace_types))) t
    )
  loop
    l_count := l_count + 1;

    if p_include_content then
      -- separate call to get the whole attachment, including content
      l_returnvalue (l_count) := get_file_attachment (l_rec.attachment_id);
    else
      l_returnvalue(l_count).attachment_id := l_rec.attachment_id;
      l_returnvalue(l_count).item_id := p_item_id;
      l_returnvalue(l_count).name := l_rec.name;
      l_returnvalue(l_count).content_type := l_rec.content_type;
      l_returnvalue(l_count).content_id := l_rec.content_id;
    end if;

    l_returnvalue(l_count).sequence_number := l_count;
    
  end loop;

  return l_returnvalue;

end get_file_attachments_as_list;


function get_file_attachments (p_item_id in varchar2) return t_file_attachment_tab pipelined
as
  l_items t_file_attachment_list;
begin
 
  /*
 
  Purpose:      get file atttachments
 
  Remarks:      does not return the actual content, use get_file_attachment() for that
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     21.04.2012  Created
   
  */
 
  l_items := get_file_attachments_as_list (p_item_id);
  
  for i in 1 .. l_items.count loop
    pipe row (l_items(i));
  end loop;

  return;
 
end get_file_attachments;


function get_file_attachment (p_attachment_id in varchar2) return t_file_attachment
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'GetAttachment';
  l_xml                          xmltype;
  l_returnvalue                  t_file_attachment;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa494316(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:GetAttachment>
          <m:AttachmentShape />
          <m:AttachmentIds>
            <t:AttachmentId Id="' || p_attachment_id || '"/>
          </m:AttachmentIds>
        </m:GetAttachment>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;


begin
 
  /*
 
  Purpose:      get file attachment
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
 
  */
 
  l_xml := make_request (l_soap_action, get_request_envelope);

  l_returnvalue.attachment_id := flex_ws_api.parse_xml(l_xml, '//*/m:Attachments/t:FileAttachment/t:AttachmentId/@Id', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.name := flex_ws_api.parse_xml(l_xml, '//*/m:Attachments/t:FileAttachment/t:Name/text()', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.content_type := flex_ws_api.parse_xml(l_xml, '//*/m:Attachments/t:FileAttachment/t:ContentType/text()', g_namespace_messages || ' ' || g_namespace_types);
  l_returnvalue.content_id := flex_ws_api.parse_xml(l_xml, '//*/m:Attachments/t:FileAttachment/t:ContentId/text()', g_namespace_messages || ' ' || g_namespace_types);

  l_returnvalue.content := flex_ws_api.clobbase642blob (flex_ws_api.parse_xml_clob (l_xml, '//*/m:Attachments/t:FileAttachment/t:Content/text()', g_namespace_messages || ' ' || g_namespace_types));

  return l_returnvalue;
 
end get_file_attachment;


function create_file_attachment (p_file_attachment in t_file_attachment) return varchar2
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'CreateAttachment';
  l_xml                          xmltype;
  l_returnvalue                  varchar2(2000);

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa565877(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:CreateAttachment>
          <m:ParentItemId Id="' || p_file_attachment.item_id || '" />
          <m:Attachments>
            <t:FileAttachment>
              <t:Name>' || dbms_xmlgen.convert(p_file_attachment.name, dbms_xmlgen.entity_encode) || '</t:Name>
              <t:Content>' || flex_ws_api.blob2clobbase64 (p_file_attachment.content) || '</t:Content>
            </t:FileAttachment>
          </m:Attachments>
        </m:CreateAttachment>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;


begin
 
  /*
 
  Purpose:      create file attachment
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.05.2012  Created
 
  */
 
  l_xml := make_request (l_soap_action, get_request_envelope);

  -- TODO: verify that value is returned... 
  l_returnvalue := flex_ws_api.parse_xml(l_xml, '//*/m:Attachments/t:FileAttachment/t:AttachmentId/@Id', g_namespace_messages || ' ' || g_namespace_types);

  return l_returnvalue;
 
end create_file_attachment;


procedure delete_attachment (p_attachment_id in varchar2)
as

  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'DeleteAttachment';
  l_xml                          xmltype;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      see http://msdn.microsoft.com/en-us/library/aa580782(v=exchg.140).aspx
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     02.05.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:DeleteAttachment>
          <m:AttachmentIds>
            <t:AttachmentId Id="' || p_attachment_id || '"/>
          </m:AttachmentIds>
        </m:DeleteItem>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;

begin

  /*
 
  Purpose:      delete attachment
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     02.05.2012  Created
 
  */
  
  l_xml := make_request (l_soap_action, get_request_envelope);

end delete_attachment;


function resolve_names_as_list (p_unresolved_entry in varchar2,
                                p_return_full_contact_data in boolean := false) return t_resolution_list
as

  l_count                        pls_integer := 0;
  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'ResolveNames';
  l_xml                          xmltype;
  l_returnvalue                  t_resolution_list;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:ResolveNames ReturnFullContactData="' || get_bool_str (p_return_full_contact_data) || '">
          <m:UnresolvedEntry>' || dbms_xmlgen.convert(p_unresolved_entry, dbms_xmlgen.entity_encode) || '</m:UnresolvedEntry>
        </m:ResolveNames>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;


begin


  /*
 
  Purpose:      resolve names
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.05.2012  Created
 
  */

  l_xml := make_request (l_soap_action, get_request_envelope);

  for l_rec in (
    select extractValue(value(t), '*/t:Name', g_namespace_messages || ' ' || g_namespace_types) as name,
      extractValue(value(t), '*/t:EmailAddress', g_namespace_messages || ' ' || g_namespace_types) as email_address,
      extractValue(value(t), '*/t:RoutingType', g_namespace_messages || ' ' || g_namespace_types) as routing_type,
      extractValue(value(t), '*/t:MailboxType', g_namespace_messages || ' ' || g_namespace_types) as mailbox_type
    from table(xmlsequence(l_xml.extract('//t:Resolution/t:Mailbox', g_namespace_messages || ' ' || g_namespace_types))) t
    )
  loop
    l_count := l_count + 1;

    l_returnvalue(l_count).mailbox.name := l_rec.name;
    l_returnvalue(l_count).mailbox.email_address := l_rec.email_address;
    l_returnvalue(l_count).mailbox.routing_type := l_rec.routing_type;
    l_returnvalue(l_count).mailbox.mailbox_type := l_rec.mailbox_type;
    
  end loop;

  return l_returnvalue;

end resolve_names_as_list;


function resolve_names (p_unresolved_entry in varchar2) return t_mailbox_tab pipelined
as
  l_names t_resolution_list;
begin
 
  /*
 
  Purpose:      resolve names
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.05.2012  Created
   
  */
 
  l_names := resolve_names_as_list (p_unresolved_entry);
  
  for i in 1 .. l_names.count loop
    pipe row (l_names(i).mailbox);
  end loop;

  return;
 
end resolve_names;


function expand_public_dl_as_list (p_email_address in varchar2) return t_dl_expansion_list
as

  l_count                        pls_integer := 0;
  l_soap_action                  constant varchar2(2000) := g_soap_action_prefix || 'ExpandDL';
  l_xml                          xmltype;
  l_returnvalue                  t_dl_expansion_list;

  function get_request_envelope return clob
  as
    l_returnvalue clob;
  begin

    /*
   
    Purpose:      get request envelope
   
    Remarks:      
   
    Who     Date        Description
    ------  ----------  --------------------------------
    MBR     21.04.2012  Created
   
    */
    
    l_returnvalue := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope ' || g_namespace_soap || ' ' || g_namespace_messages || ' ' || g_namespace_types || '>
      <soap:Body>
        <m:ExpandDL>
          <m:Mailbox>
            <t:EmailAddress>' || dbms_xmlgen.convert(p_email_address, dbms_xmlgen.entity_encode) || '</t:EmailAddress>
          </m:Mailbox>
        </m:ExpandDL>
      </soap:Body>
    </soap:Envelope>';

    return l_returnvalue;

  end get_request_envelope;


begin


  /*
 
  Purpose:      expand (public) distribution list
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.05.2012  Created
 
  */

  l_xml := make_request (l_soap_action, get_request_envelope);

  for l_rec in (
    select extractValue(value(t), '*/t:Name', g_namespace_messages || ' ' || g_namespace_types) as name,
      extractValue(value(t), '*/t:EmailAddress', g_namespace_messages || ' ' || g_namespace_types) as email_address,
      extractValue(value(t), '*/t:RoutingType', g_namespace_messages || ' ' || g_namespace_types) as routing_type,
      extractValue(value(t), '*/t:MailboxType', g_namespace_messages || ' ' || g_namespace_types) as mailbox_type
    from table(xmlsequence(l_xml.extract('//m:DLExpansion/t:Mailbox', g_namespace_messages || ' ' || g_namespace_types))) t
    )
  loop
    l_count := l_count + 1;

    l_returnvalue(l_count).name := l_rec.name;
    l_returnvalue(l_count).email_address := l_rec.email_address;
    l_returnvalue(l_count).routing_type := l_rec.routing_type;
    l_returnvalue(l_count).mailbox_type := l_rec.mailbox_type;
    
  end loop;

  return l_returnvalue;

end expand_public_dl_as_list;


function expand_public_dl (p_email_address in varchar2) return t_dl_expansion_tab pipelined
as
  l_list t_dl_expansion_list;
begin
 
  /*
 
  Purpose:      resolve names
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     07.05.2012  Created
   
  */
 
  l_list := expand_public_dl_as_list (p_email_address);
  
  for i in 1 .. l_list.count loop
    pipe row (l_list(i));
  end loop;

  return;
 
end expand_public_dl;


end ms_ews_util_pkg;
/
 


