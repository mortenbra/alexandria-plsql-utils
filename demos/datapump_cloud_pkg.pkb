create or replace package body datapump_cloud_pkg
as
 
  /*
 
  Purpose:      Package handles backup to and restore from "the cloud" (Amazon S3)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.11.2011  Created
 
  */


procedure send_mail (p_to in varchar2,
                     p_subject in varchar2,
                     p_body in varchar2) 
as
  l_host                         string_util_pkg.t_max_db_varchar2 := sys_context('userenv', 'server_host');
  l_instance                     string_util_pkg.t_max_db_varchar2 := sys_context('userenv', 'instance_name');
  l_body                         string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      send email
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     16.11.2011  Created
 
  */
  
  if p_to is not null then
  
    l_body := p_body || chr(10) || chr(10) || 'Host: ' || l_host || chr(10) || 'Instance: ' || l_instance; 
 
    -- Apex security context (required for sending emails via Apex from background jobs) 
    apex_util_pkg.set_apex_security_context (p_schema => user);
  
    debug_pkg.printf('Sending email to %1 with subject "%2"', p_to, p_subject);

    apex_mail.send (p_to => p_to, p_from => 'backup-agent@' || l_host, p_body => l_body, p_subj => p_subject);
    apex_mail.push_queue;
  
  end if; 

end send_mail;
 
 
procedure add_progress (p_progress in out varchar2,
                        p_message in varchar2) 
as
begin
 
  /*
 
  Purpose:      add message to progress string
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     06.11.2011  Created
 
  */
  
  p_progress := p_progress || chr(10) || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss') || ' : ' || p_message;

end add_progress;


procedure backup_schema_to_s3 (p_aws_key in varchar2,
                               p_aws_password in varchar2,
                               p_aws_bucket in varchar2,
                               p_aws_folder in varchar2,
                               p_directory_name in varchar2,
                               p_file_name in varchar2 := null,
                               p_email_failure in varchar2 := null,
                               p_email_success in varchar2 := null,
                               p_encrypt in boolean := false,
                               p_compress in boolean := false,
                               p_version in varchar2 := null,
                               p_gmt_offset in number := null) 
as
  l_start_date                 date := sysdate;
  l_progress                   string_util_pkg.t_max_pl_varchar2;
  l_error_code                 number;
  l_error_message              string_util_pkg.t_max_pl_varchar2;
  l_error_backtrace            string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      backup schema to Amazon S3
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.11.2011  Created
 
  */
 
  begin
  
    add_progress (l_progress, 'Starting export...');
    datapump_util_pkg.export_schema_to_file (p_directory_name, p_file_name, p_version, null, p_compress);

    add_progress (l_progress, 'Setting AWS authentication, GMT offset = ' || p_gmt_offset);
    amazon_aws_auth_pkg.init (p_aws_key, p_aws_password, p_gmt_offset);

    add_progress (l_progress, 'Uploading remote file ' || p_aws_folder || '/' || p_file_name || '.dmp');
    amazon_aws_s3_pkg.new_object(p_aws_bucket, p_aws_folder || '/' || p_file_name || '.dmp', file_util_pkg.get_blob_from_file(p_directory_name, p_file_name || '.dmp'), 'application/octet-stream');
    add_progress (l_progress, 'Uploading remote file ' || p_aws_folder || '/' || p_file_name || '.log');
    amazon_aws_s3_pkg.new_object(p_aws_bucket, p_aws_folder || '/' || p_file_name || '.log', file_util_pkg.get_blob_from_file(p_directory_name, p_file_name || '.log'), 'text/plain');
    
    -- delete the dump file, leave the log file
    add_progress (l_progress, 'Deleting local file ' || p_file_name || '.dmp');
    utl_file.fremove (p_directory_name, p_file_name || '.dmp');

    add_progress (l_progress, 'SUCCESS! Time elapsed: ' || date_util_pkg.fmt_time(sysdate - l_start_date));

    send_mail (p_email_success, 'Backup Success: ' || p_file_name,  l_progress);

  exception
    when others then
      l_error_code := sqlcode;
      l_error_message := sqlerrm;
      l_error_backtrace := dbms_utility.format_error_backtrace;
      add_progress (l_progress, 'ERROR: ' || l_error_message);
      add_progress (l_progress, 'Error Stack: ' || l_error_backtrace);
      send_mail (p_email_failure, 'BACKUP FAILURE: ' || p_file_name || ', ORA' || l_error_code, l_progress);
  end;
 
end backup_schema_to_s3;
 
 
procedure restore_schema_from_s3 (p_aws_key in varchar2,
                                  p_aws_password in varchar2,
                                  p_aws_bucket in varchar2,
                                  p_aws_folder in varchar2,
                                  p_file_name in varchar2,
                                  p_directory_name in varchar2,
                                  p_decrypt in boolean := false,
                                  p_decompress in boolean := false,
                                  p_remap_to_schema in varchar2 := null,
                                  p_gmt_offset in number := null) 
as
  l_blob blob;
begin
 
  /*
 
  Purpose:      restore schema from Amazon S3
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.11.2011  Created
 
  */

  amazon_aws_auth_pkg.init (p_aws_key, p_aws_password, p_gmt_offset);
  
  l_blob := amazon_aws_s3_pkg.get_object (p_aws_bucket, p_aws_folder || '/' || p_file_name || '.dmp');
  
  file_util_pkg.save_blob_to_file (p_directory_name, p_file_name || '.dmp', l_blob);
 
  datapump_util_pkg.import_schema_from_file (p_directory_name, p_file_name || '.dmp', p_file_name || '.log', p_remap_to_schema => p_remap_to_schema);
 
end restore_schema_from_s3;
 
end datapump_cloud_pkg;
/
 


