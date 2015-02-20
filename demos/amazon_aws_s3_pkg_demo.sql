-- NOTE: all the following examples assume that the authentication package
--       has been initialized by running the following code:

begin
  amazon_aws_auth_pkg.init ('my_aws_id', 'my_aws_key', p_gmt_offset => -1);
end;

-- create new bucket (default region)

begin
  debug_pkg.debug_on;
  amazon_aws_s3_pkg.new_bucket('my-bucket-name');
end;


-- create new bucket (in specific region)

begin
  debug_pkg.debug_on;
  amazon_aws_s3_pkg.new_bucket('my-bucket-name', amazon_aws_s3_pkg.g_region_eu);
end;


-- get list of buckets

declare
  l_list amazon_aws_s3_pkg.t_bucket_list;
begin
  debug_pkg.debug_on;
  l_list := amazon_aws_s3_pkg.get_bucket_list;
  if l_list.count > 0 then
    for i in 1..l_list.count loop
      debug_pkg.printf('list(%1) = %2, creation date = %3', i, l_list(i).bucket_name, l_list(i).creation_date);
    end loop;
  end if;
end;

-- get list of buckets via SQL

select *
from table(amazon_aws_s3_pkg.get_bucket_tab()) t
order by 1


-- get list of objects

declare
  l_list amazon_aws_s3_pkg.t_object_list;
begin
  debug_pkg.debug_on;
  l_list := amazon_aws_s3_pkg.get_object_list ('my-bucket-name');
  if l_list.count > 0 then
    for i in 1..l_list.count loop
      debug_pkg.printf('list(%1) = %2, last modified = %3', i, l_list(i).key, l_list(i).last_modified);
    end loop;
  end if;
end;

-- get list of objects via SQL

select *
from table(amazon_aws_s3_pkg.get_object_tab('my-bucket-name')) t
order by 2 desc

-- with some filtering, and restricting number of keys returned

select *
from table(amazon_aws_s3_pkg.get_object_tab('my-bucket-name', 'my', 4)) t
order by 2 desc


-- get download link (with expiry date)

select amazon_aws_s3_pkg.get_download_url('my-bucket-name', 'my_pdf.pdf', sysdate +1)
from dual

-- download file (and save to disk)

declare
  l_url  varchar2(2000);
  l_blob blob;
begin
  l_url := amazon_aws_s3_pkg.get_download_url ('my-bucket-name', 'my-uploaded-pdf.pdf', sysdate + 1);
  l_blob := http_util_pkg.get_blob_from_url (l_url);
  file_util_pkg.save_blob_to_file ('DEVTEST_TEMP_DIR', 'my_pdf_downloaded_from_s3_' || to_char(sysdate, 'yyyyhh24miss') || '.pdf', l_blob);
end;


-- download file (and save to disk) -- shorter version

declare
  l_blob blob;
begin
  l_blob := amazon_aws_s3_pkg.get_object ('my-bucket-name', 'my-uploaded-pdf.pdf');
  file_util_pkg.save_blob_to_file ('DEVTEST_TEMP_DIR', 'my_pdf_downloaded_from_s3_' || to_char(sysdate, 'yyyyhh24miss') || '.pdf', l_blob);
end;


-- upload new object (retrieved from URL)

declare
  l_blob blob;
begin
  l_blob := http_util_pkg.get_blob_from_url ('http://docs.amazonwebservices.com/AmazonS3/latest/API/images/title-swoosh-logo.gif');
  amazon_aws_s3_pkg.new_object ('my-bucket-name', 'my-uploaded-image3.gif', l_blob, 'image/gif');
end;


-- upload file into a folder-like structure
-- note: there is no concept of folders in S3, but you can use slash in key names, which some clients present as folders
-- see http://stackoverflow.com/questions/1939743/amazon-s3-boto-how-to-create-folder

declare
  l_blob blob;
begin
  l_blob := http_util_pkg.get_blob_from_url ('http://docs.amazonwebservices.com/AmazonS3/latest/API/images/title-swoosh-logo.gif');
  amazon_aws_s3_pkg.new_object ('my-bucket-name', 'my-new-folder/some-subfolder/the-amazon-logo.gif', l_blob, 'image/gif');
end;

-- upload object and set ACL

declare
  l_blob blob;
begin
  l_blob := http_util_pkg.get_blob_from_url ('http://docs.amazonwebservices.com/AmazonS3/latest/API/images/title-swoosh-logo.gif');
  amazon_aws_s3_pkg.new_object ('my-bucket-name', 'my-new-folder/some-subfolder/the-amazon-logo3.gif', l_blob, 'image/gif', amazon_aws_s3_pkg.g_acl_public_read);
end;

-- upload new object from file

declare
  l_blob blob;
begin
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'my_pdf.pdf');
  amazon_aws_s3_pkg.new_object ('my-bucket-name', 'my-uploaded-pdf2.pdf', l_blob, 'application/pdf');
end;


-- get file from disk, zip it, and upload it


declare
  l_blob blob;
  l_zip blob;
begin
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'GeoIPCountryWhois2.csv');
  zip_util_pkg.add_file (l_zip, 'my-csv-inside-a-zip.csv', l_blob);
  zip_util_pkg.finish_zip (l_zip);
  amazon_aws_s3_pkg.new_object ('my-bucket-name', 'my-compressed-file.zip', l_zip, 'application/zip');
end;


-- delete object

begin
  amazon_aws_s3_pkg.delete_object ('my-bucket-name', 'my-uploaded-pdf2.pdf');
end;


-- delete bucket

begin
  amazon_aws_s3_pkg.delete_bucket ('my-bucket-name');
end;

-- set object ACL

begin
  debug_pkg.debug_on;
  amazon_aws_s3_pkg.set_object_acl ('my-bucket-name', 'my-uploaded-pdf2.pdf', amazon_aws_s3_pkg.g_acl_public_read);
end;


-- get object owner

declare
  l_owner amazon_aws_s3_pkg.t_owner;
begin
  debug_pkg.debug_on;
  l_owner := amazon_aws_s3_pkg.get_object_owner ('my-bucket-name', 'my-uploaded-pdf2.pdf');
  debug_pkg.printf('owner name = %1, owner id = %2', l_owner.user_name, l_owner.user_id);
end;

-- get object grantee list

declare
  l_list amazon_aws_s3_pkg.t_grantee_list;
begin
  debug_pkg.debug_on;
  l_list := amazon_aws_s3_pkg.get_object_grantee_list ('my-bucket-name', 'my-uploaded-pdf2.pdf');
  if l_list.count > 0 then
    for i in 1..l_list.count loop
      debug_pkg.printf('%1 - grantee type = %2, user id = %3, user name = %4, group = %5, permission = %6', i, l_list(i).grantee_type, l_list(i).user_id, l_list(i).user_name, l_list(i).group_uri, l_list(i).permission);
    end loop;
  end if;
end;

