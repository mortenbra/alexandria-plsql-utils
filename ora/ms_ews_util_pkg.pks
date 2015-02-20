create or replace package ms_ews_util_pkg
as
 
  /*
 
  Purpose:      Package handles Microsoft Exchange Web Services (EWS)
 
  Remarks:      see http://msdn.microsoft.com/en-us/library/bb204119(v=exchg.140).aspx
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     19.02.2012  Created
  MBR     24.04.2012  Added item and attachment operations
  MBR     07.05.2012  Added utility operations (resolve names, expand distribution list)
 
  */
  
  --------
  -- types
  --------

  -- see http://msdn.microsoft.com/en-us/library/aa565036(v=exchg.140).aspx
  type t_mailbox is record (
    name varchar2(2000),
    email_address varchar2(2000),
    routing_type varchar2(255),
    mailbox_type varchar2(255),
    item_id varchar2(2000)
   );
   
  type t_mailbox_tab is table of t_mailbox; 

  -- see http://msdn.microsoft.com/en-us/library/aa581315(v=exchg.140).aspx
  type t_contact is record (
    item_id varchar2(2000)
    -- TODO: lots more fields
  );
  
  -- see http://msdn.microsoft.com/en-us/library/aa581011(v=exchg.140).aspx
  type t_resolution is record (
    mailbox t_mailbox,
    contact t_contact
  );
  
  -- see http://msdn.microsoft.com/en-us/library/aa580614(v=exchg.140).aspx
  type t_resolution_list is table of t_resolution index by binary_integer;

  -- see http://msdn.microsoft.com/en-us/library/aa564322(v=exchg.140).aspx
  type t_dl_expansion_list is table of t_mailbox index by binary_integer;
  type t_dl_expansion_tab is table of t_mailbox;
  
  -- see http://msdn.microsoft.com/en-us/library/aa581334(v=exchg.140).aspx
  type t_folder is record (
    sequence_number number,
    folder_id varchar2(2000),
    display_name varchar2(2000),
    total_count number,
    child_folder_count number,
    unread_count number
  );

  type t_folder_list is table of t_folder index by binary_integer;
  type t_folder_tab is table of t_folder;
 
  type t_item is record (
    -- general Item info, see http://msdn.microsoft.com/en-us/library/aa580790(v=exchg.140).aspx
    sequence_number number,
    item_id varchar2(2000),
    change_key varchar2(2000),
    parent_folder_id varchar2(2000),
    item_class varchar2(255),
    item_size number,
    subject varchar2(2000),
    sensitivity varchar2(255),
    datetime_created date,
    datetime_sent date,
    datetime_received date,
    has_attachments varchar2(10),
    mime_content clob,
    body clob,
    -- (mail) Message, see http://msdn.microsoft.com/en-us/library/aa494306(v=exchg.140).aspx
    from_mailbox_name varchar2(2000),
    is_read varchar2(10),
    -- CalendarItem, see http://msdn.microsoft.com/en-us/library/aa564765(v=exchg.140).aspx
    location varchar2(2000),
    organizer_mailbox_name varchar2(2000),
    start_date date,
    end_date date,
    legacy_free_busy_status varchar2(255),
    reminder_is_set varchar2(10),
    reminder_minutes_before_start number,
    is_all_day_event varchar2(10),
    -- Task item, see http://msdn.microsoft.com/en-us/library/aa563930(v=exchg.140).aspx
    due_date date,
    status varchar2(255),
    percent_complete number,
    total_work number
  );

  type t_item_list is table of t_item index by binary_integer;
  type t_item_tab is table of t_item;

  -- see http://msdn.microsoft.com/en-us/library/aa580492(v=exchg.140).aspx
  type t_file_attachment is record (
    sequence_number number,
    attachment_id varchar2(2000),
    item_id varchar2(2000),
    name varchar2(2000),
    content_type varchar2(2000),
    content_id varchar2(2000),
    attachment_size number,
    content blob
  );  

  type t_file_attachment_list is table of t_file_attachment index by binary_integer;
  type t_file_attachment_tab is table of t_file_attachment;

  ------------
  -- constants
  ------------
  
  g_true                         constant varchar2(10) := 'true';
  g_false                        constant varchar2(10) := 'false';
  
  -- "Distinguished Folders", folders that can be referenced by name, see http://msdn.microsoft.com/en-us/library/aa580808(v=exchg.140).aspx
  -- for other folders, use find_folders to get folder id
  -- NOTE: when adding to this list, make sure to update the internal function is_distinguished_folder_id ()
  g_folder_id_root               constant varchar2(255) := 'root';
  g_folder_id_message_root       constant varchar2(255) := 'msgfolderroot';
  g_folder_id_inbox              constant varchar2(255) := 'inbox';
  g_folder_id_sent_items         constant varchar2(255) := 'sentitems';
  g_folder_id_deleted_items      constant varchar2(255) := 'deleteditems';
  g_folder_id_outbox             constant varchar2(255) := 'outbox';
  g_folder_id_junk_email         constant varchar2(255) := 'junkemail';
  g_folder_id_drafts             constant varchar2(255) := 'drafts';
  g_folder_id_calendar           constant varchar2(255) := 'calendar';
  
  -- item classes, see http://msdn.microsoft.com/en-us/library/ff861573.aspx
  g_item_class_unknown           constant varchar2(255) := 'IPM';
  g_item_class_appointment       constant varchar2(255) := 'IPM.Appointment';
  g_item_class_contact           constant varchar2(255) := 'IPM.Contact';
  g_item_class_message           constant varchar2(255) := 'IPM.Note';
  g_item_class_task              constant varchar2(255) := 'IPM.Task';
  g_item_class_meeting_request   constant varchar2(255) := 'IPM.Schedule.Meeting.Request';
  
  -- Body Type, see http://msdn.microsoft.com/en-us/library/aa565622(v=exchg.140).aspx
  g_body_type_best               constant varchar2(255) := 'Best';
  g_body_type_html               constant varchar2(255) := 'HTML';
  g_body_type_text               constant varchar2(255) := 'Text';
 
  -- Delete Type, see http://msdn.microsoft.com/en-us/library/ff406163(v=exchg.140).aspx
  g_delete_type_hard_delete      constant varchar2(255) := 'HardDelete';
  g_delete_type_move_to_d_items  constant varchar2(255) := 'MoveToDeletedItems';
  g_delete_type_soft_delete      constant varchar2(255) := 'SoftDelete';
  
  -- Message Disposition attribute, see http://msdn.microsoft.com/en-us/library/aa565209(v=exchg.140).aspx
  g_message_disp_save_only       constant varchar2(255) := 'SaveOnly';
  g_message_disp_send_only       constant varchar2(255) := 'SendOnly';
  g_message_disp_send_and_save   constant varchar2(255) := 'SendAndSaveCopy';
  
  -- Send Meeting Invitations attribute, see http://msdn.microsoft.com/en-us/library/aa565209(v=exchg.140).aspx
  g_meeting_inv_send_to_none     constant varchar2(255) := 'SendToNone';
  g_meeting_inv_send_only_to_all constant varchar2(255) := 'SendOnlyToAll';
  g_meeting_inv_send_to_all_save constant varchar2(255) := 'SendToAllAndSaveCopy';
  
  -- Legacy Free Busy Status, see http://msdn.microsoft.com/en-us/library/aa566143(v=exchg.140).aspx
  g_free_busy_status_free        constant varchar2(255) := 'Free';
  g_free_busy_status_tentative   constant varchar2(255) := 'Tentative';
  g_free_busy_status_busy        constant varchar2(255) := 'Busy';
  g_free_busy_status_out_of_off  constant varchar2(255) := 'OOF';
  g_free_busy_status_no_data     constant varchar2(255) := 'NoData';
  
  -- task status, see http://msdn.microsoft.com/en-us/library/aa563980(v=exchg.140).aspx
  g_task_status_not_started      constant varchar2(255) := 'NotStarted';
  g_task_status_in_progress      constant varchar2(255) := 'InProgress';
  g_task_status_completed        constant varchar2(255) := 'Completed';
  g_task_status_waiting_on_other constant varchar2(255) := 'WaitingOnOthers';
  g_task_status_deferred         constant varchar2(255) := 'Deferred';
  
  -- mailbox type, see http://msdn.microsoft.com/en-us/library/aa563493(v=exchg.140).aspx
  g_mailbox_type_mailbox         constant varchar2(255) := 'Mailbox';
  g_mailbox_type_public_dl       constant varchar2(255) := 'PublicDL';
  g_mailbox_type_private_dl      constant varchar2(255) := 'PrivateDL';
  g_mailbox_type_contact         constant varchar2(255) := 'Contact';
  g_mailbox_type_public_folder   constant varchar2(255) := 'PublicFolder';
  g_mailbox_type_unknown         constant varchar2(255) := 'Unknown';
  g_mailbox_type_one_off         constant varchar2(255) := 'OneOff';
  
  -----------------
  -- authentication
  -----------------

  -- initialize settings
  procedure init (p_service_url in varchar2,
                  p_username in varchar2,
                  p_password in varchar2,
                  p_wallet_path in varchar2 := null,
                  p_wallet_password in varchar2 := null);
 
  --------------------
  -- folder operations
  --------------------

  -- find folders
  function find_folders_as_list (p_parent_folder_id in varchar2 := null) return t_folder_list;

  -- find folder
  function find_folders (p_parent_folder_id in varchar2 := null) return t_folder_tab pipelined;
  
  -- get folder id by name
  function get_folder_id_by_name (p_folder_name in varchar2,
                                  p_parent_folder_id in varchar2 := null) return varchar2;

  -- get folder
  function get_folder (p_folder_id in varchar2) return t_folder;

  ------------------
  -- item operations
  ------------------

  -- find items
  function find_items_as_list (p_folder_id in varchar2 := null,
                               p_search_string in varchar2 := null,
                               p_search_from_date in date := null,
                               p_search_to_date in date := null,
                               p_max_rows in number := null,
                               p_offset in number := null,
                               p_username in varchar2 := null) return t_item_list;
 
  -- find items
  function find_items (p_folder_id in varchar2 := null,
                       p_search_string in varchar2 := null,
                       p_search_from_date in date := null,
                       p_search_to_date in date := null,
                       p_max_rows in number := null,
                       p_offset in number := null,
                       p_username in varchar2 := null) return t_item_tab pipelined;

  -- get item
  function get_item (p_item_id in varchar2,
                     p_body_type in varchar2 := null,
                     p_include_mime_content in boolean := false) return t_item;

  -- move item
  procedure move_item (p_item_id in varchar2,
                       p_folder_id in varchar2);

  -- copy item
  procedure copy_item (p_item_id in varchar2,
                       p_folder_id in varchar2);

  -- delete item
  procedure delete_item (p_item_id in varchar2,
                         p_delete_type in varchar2 := null);
                         
  -- send item
  procedure send_item (p_item_id in varchar2,
                       p_save_item_to_folder in boolean := true);

  -- create calendar item
  function create_calendar_item (p_item in t_item,
                                 p_send_meeting_invitations in varchar2 := null,
                                 p_required_attendees in t_str_array := null) return varchar2;
  
  -- create task item
  function create_task_item (p_item in t_item) return varchar2;

  -- create message item
  function create_message_item (p_item in t_item,
                                p_message_disposition in varchar2 := null,
                                p_to_recipients in t_str_array := null) return varchar2;

  -- TODO: generic update_item ()
  -- the following is just a proof-of-concept that demonstrates an update  
  procedure update_item_is_read (p_item_id in varchar2,
                                 p_change_key in varchar2,
                                 p_is_read in boolean);
 
  ------------------------
  -- attachment operations
  ------------------------
  
  -- note: attachments can be either file attachments, or item attachments (ie other messages)
  --       currently, just the file attachment operations are supported

  -- get item file attachments
  function get_file_attachments_as_list (p_item_id in varchar2,
                                         p_include_content in boolean := false) return t_file_attachment_list;

  -- get item file attachments
  function get_file_attachments (p_item_id in varchar2) return t_file_attachment_tab pipelined;

  -- get file attachment
  function get_file_attachment (p_attachment_id in varchar2) return t_file_attachment;

  -- create file attachment
  function create_file_attachment (p_file_attachment in t_file_attachment) return varchar2; 
  
  -- delete attachment
  procedure delete_attachment (p_attachment_id in varchar2);
  
  ---------------------
  -- utility operations
  ---------------------
  
  -- resolve names
  function resolve_names_as_list (p_unresolved_entry in varchar2,
                                  p_return_full_contact_data in boolean := false) return t_resolution_list;

  -- resolve names
  function resolve_names (p_unresolved_entry in varchar2) return t_mailbox_tab pipelined;

  -- expand (public) distribution list
  function expand_public_dl_as_list (p_email_address in varchar2) return t_dl_expansion_list;

  -- expand (public) distribution list
  function expand_public_dl (p_email_address in varchar2) return t_dl_expansion_tab pipelined;


end ms_ews_util_pkg;
/

