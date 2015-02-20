create or replace package datapump_cloud_pkg
as
 
  /*
 
  Purpose:      Package handles backup to and restore from "the cloud" (Amazon S3)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     05.11.2011  Created
 
  */
 
 
  -- backup schema to Amazon S3
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
                                 p_gmt_offset in number := null);
 
  -- restore schema from Amazon S3
  procedure restore_schema_from_s3 (p_aws_key in varchar2,
                                    p_aws_password in varchar2,
                                    p_aws_bucket in varchar2,
                                    p_aws_folder in varchar2,
                                    p_file_name in varchar2,
                                    p_directory_name in varchar2,
                                    p_decrypt in boolean := false,
                                    p_decompress in boolean := false,
                                    p_remap_to_schema in varchar2 := null,
                                    p_gmt_offset in number := null);
 
 
end datapump_cloud_pkg;
/

