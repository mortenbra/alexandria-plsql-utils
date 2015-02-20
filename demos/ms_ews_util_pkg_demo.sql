
-- package must be initialized before use, at least once per session (in Apex, once per page view)

begin
  debug_pkg.debug_on;
  ms_ews_util_pkg.init('https://thycompany.com/ews/Exchange.asmx', 'domain\user.name', 'your_password', 'file:c:\path\to\Oracle\wallet\folder\on\db\server', 'wallet_password');
end;


-- resolve names

declare
  l_names ms_ews_util_pkg.t_resolution_list;
begin
  debug_pkg.debug_on;
  l_names := ms_ews_util_pkg.resolve_names_as_list('john');
  for i in 1 .. l_names.count loop
    debug_pkg.printf('name %1, name = %2, email = %3', i, l_names(i).mailbox.name, l_names(i).mailbox.email_address);
  end loop;
end;


-- resolve names (via SQL)

select *
from table(ms_ews_util_pkg.resolve_names ('john'))


-- expand distribution list

declare
  l_names ms_ews_util_pkg.t_dl_expansion_list;
begin
  debug_pkg.debug_on;
  l_names := ms_ews_util_pkg.expand_public_dl_as_list('some_mailing_list@your.company');
  for i in 1 .. l_names.count loop
    debug_pkg.printf('name %1, name = %2, email = %3', i, l_names(i).name, l_names(i).email_address);
  end loop;
end;


-- get folder

declare
  l_folder ms_ews_util_pkg.t_folder;
begin
  debug_pkg.debug_on;
  l_folder := ms_ews_util_pkg.get_folder (ms_ews_util_pkg.g_folder_id_inbox);
  debug_pkg.printf('folder id = %1, display name = %2', l_folder.folder_id, l_folder.display_name);
  debug_pkg.printf('total count = %1', l_folder.total_count);
  debug_pkg.printf('child folder count = %1', l_folder.child_folder_count);
  debug_pkg.printf('unread count = %1', l_folder.unread_count);
end;


-- find up to 3 items in specified folder

declare
  l_items ms_ews_util_pkg.t_item_list;
begin
  debug_pkg.debug_on;
  l_items := ms_ews_util_pkg.find_items_as_list('inbox', p_max_rows => 3);
  for i in 1 .. l_items.count loop
    debug_pkg.printf('item %1, subject = %2', i, l_items(i).subject);
  end loop;
end;


-- get items in predefined folder

select *
from table(ms_ews_util_pkg.find_folders('inbox'))

-- hide it behind a view...

create or replace view my_inbox_v
as
select datetime_received, subject, from_mailbox_name, is_read, has_attachments, item_id
from table(ms_ews_util_pkg.find_items('inbox'));

-- get items in predefined folder, and search subject

select *
from table(ms_ews_util_pkg.find_items('inbox', 'the search term'))

-- get items in user-defined folder

select *
from table(ms_ews_util_pkg.find_items('the_folder_id'))

-- get items in user-defined folder, by name

select *
from table(ms_ews_util_pkg.find_items(
             ms_ews_util_pkg.get_folder_id_by_name('Some Folder Name', 'inbox')
            )
          )



-- get item (email message)

declare
  l_item ms_ews_util_pkg.t_item;
begin
  debug_pkg.debug_on;
  l_item := ms_ews_util_pkg.get_item ('the_item_id', p_include_mime_content => true);
  debug_pkg.printf('item %1, subject = %2', l_item.item_id, l_item.subject);
  debug_pkg.printf('body = %1', substr(l_item.body,1,2000));
  debug_pkg.printf('length of MIME content = %1', length(l_item.mime_content));
end;

-- get item (calendar item)

declare
  l_item ms_ews_util_pkg.t_item;
begin
  debug_pkg.debug_on;
  l_item := ms_ews_util_pkg.get_item ('the_item_id', p_body_type => 'Text', p_include_mime_content => true);
  debug_pkg.printf('item %1, class = %2, subject = %3', l_item.item_id, l_item.item_class, l_item.subject);
  debug_pkg.printf('body = %1', substr(l_item.body,1,2000));
  debug_pkg.printf('length of MIME content = %1', length(l_item.mime_content));
  debug_pkg.printf('start date = %1, location = %2, organizer = %3', l_item.start_date, l_item.location, l_item.organizer_mailbox_name);
end;


-- create calendar item

declare
  l_item ms_ews_util_pkg.t_item;
begin
  debug_pkg.debug_on;
  l_item.subject := 'Appointment added via PL/SQL';
  l_item.body := 'Some text here...';
  l_item.start_date := sysdate + 1;
  l_item.end_date := sysdate + 2;
  l_item.item_id := ms_ews_util_pkg.create_calendar_item (l_item);
  debug_pkg.printf('created item with id = %1', l_item.item_id);
end;


-- create task item

declare
  l_item ms_ews_util_pkg.t_item;
begin
  debug_pkg.debug_on;
  l_item.subject := 'Task added via PL/SQL';
  l_item.body := 'Some text here...';
  l_item.due_date := sysdate + 1;
  l_item.status := ms_ews_util_pkg.g_task_status_in_progress;
  l_item.item_id := ms_ews_util_pkg.create_task_item (l_item);
  debug_pkg.printf('created item with id = %1', l_item.item_id);
end;


-- create message item

declare
  l_item ms_ews_util_pkg.t_item;
begin
  debug_pkg.debug_on;
  l_item.subject := 'Message added via PL/SQL';
  l_item.body := 'Some text here...';
  l_item.item_id := ms_ews_util_pkg.create_message_item (l_item, p_to_recipients => t_str_array('recipient1@some.company', 'recipient2@another.company'));
  debug_pkg.printf('created item with id = %1', l_item.item_id);
end;

-- update item
-- item id and change key can be retrieved with following query:
-- select item_id, change_key, subject, is_read from table(ms_ews_util_pkg.find_items('inbox'))

declare
  l_item_id varchar2(2000) := 'the_item_id';
  l_change_key varchar2(2000) := 'the_change_key';
begin
  ms_ews_util_pkg.update_item_is_read (l_item_id, l_change_key, p_is_read => true);
end;


-- get list of attachments

select *
from table(ms_ews_util_pkg.get_file_attachments('the_item_id'))

-- download and save 1 attachment

declare
  l_attachment ms_ews_util_pkg.t_file_attachment;
begin
  debug_pkg.debug_on;
  l_attachment := ms_ews_util_pkg.get_file_attachment ('the_attachment_id');
  file_util_pkg.save_blob_to_file('DEVTEST_TEMP_DIR', l_attachment.name, l_attachment.content);
end;


-- create attachment (attach file to existing item/email)

declare
  l_attachment ms_ews_util_pkg.t_file_attachment;
begin
  debug_pkg.debug_on;
  l_attachment.item_id := 'the_item_id';
  l_attachment.name := 'Attachment added via PL/SQL';
  l_attachment.content := file_util_pkg.get_blob_from_file('DEVTEST_TEMP_DIR', 'some_file_such_as_a_nice_picture.jpg');
  l_attachment.attachment_id := ms_ews_util_pkg.create_file_attachment (l_attachment);
  debug_pkg.printf('created attachment with id = %1', l_attachment.attachment_id);
end;



-- sqlplus demo

set pagesize 999
column subject format a30
column from_mailbox_name format a20
column is_read format a20

exec ms_ews_util_pkg.init('...');

-- find items in specified folder with given search term, received between 6 to 3 months ago

select subject, from_mailbox_name, is_read
from table(
  ms_ews_util_pkg.find_items(
    ms_ews_util_pkg.get_folder_id_by_name('Development', 'inbox'),
    'your search term',
    sysdate - 120, sysdate - 60
  )
);
