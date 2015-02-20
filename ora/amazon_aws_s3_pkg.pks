create or replace package amazon_aws_s3_pkg
as

  /*

  Purpose:   PL/SQL wrapper package for Amazon AWS S3 API

  Remarks:   inspired by the whitepaper "Building an Amazon S3 Client with Application Express 4.0" by Jason Straub
             see http://jastraub.blogspot.com/2011/01/building-amazon-s3-client-with.html
             
  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     09.01.2011  Created
  MBR     16.02.2013  Added enhancements from Jeffrey Kemp, see http://code.google.com/p/plsql-utils/issues/detail?id=14 to http://code.google.com/p/plsql-utils/issues/detail?id=17
  
  */

  type t_bucket is record (
    bucket_name varchar2(255),
    creation_date date
  );

  type t_bucket_list is table of t_bucket index by binary_integer;
  type t_bucket_tab is table of t_bucket;
  
  type t_object is record (
    key varchar2(4000),
    size_bytes number,
    last_modified date
  );

  type t_object_list is table of t_object index by binary_integer;
  type t_object_tab is table of t_object;
  
  type t_owner is record (
    user_id varchar2(200),
    user_name varchar2(200)
  );

  type t_grantee is record (
    grantee_type varchar2(20),  -- CanonicalUser or Group
    user_id varchar2(200),      -- for users
    user_name varchar2(200),    -- for users
    group_uri varchar2(200),    -- for groups
    permission varchar2(20)     -- FULL_CONTROL, WRITE, READ_ACP
  );
  
  type t_grantee_list is table of t_grantee index by binary_integer;
  type t_grantee_tab is table of t_grantee;
  
  -- bucket regions 
  -- see http://aws.amazon.com/articles/3912?_encoding=UTF8&jiveRedirect=1#s3
  -- see http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
  g_region_us_standard           constant varchar2(255) := null;
  g_region_us_west_california    constant varchar2(255) := 'us-west-1';
  g_region_us_west_oregon        constant varchar2(255) := 'us-west-2';
  g_region_eu_ireland            constant varchar2(255) := 'EU';
  g_region_asia_pacific_singapor constant varchar2(255) := 'ap-southeast-1';
  g_region_asia_pacific_sydney   constant varchar2(255) := 'ap-southeast-2';
  g_region_asia_pacific_tokyo    constant varchar2(255) := 'ap-northeast-1';
  g_region_south_america_sao_p   constant varchar2(255) := 'sa-east-1';
  
  -- deprecated region constants, will be removed in next release (use constants above instead)
  g_region_eu                    constant varchar2(255) := 'EU';
  g_region_us_west_1             constant varchar2(255) := 'us-west-1';
  g_region_us_west_2             constant varchar2(255) := 'us-west-2';
  g_region_asia_pacific_1        constant varchar2(255) := 'ap-southeast-1'; 
  
  -- predefined access policies
  -- see http://docs.amazonwebservices.com/AmazonS3/latest/dev/index.html?RESTAccessPolicy.html

  g_acl_private                  constant varchar2(255) := 'private';
  g_acl_public_read              constant varchar2(255) := 'public-read';
  g_acl_public_read_write        constant varchar2(255) := 'public-read-write';
  g_acl_authenticated_read       constant varchar2(255) := 'authenticated-read';
  g_acl_bucket_owner_read        constant varchar2(255) := 'bucket-owner-read';
  g_acl_bucket_owner_full_ctrl   constant varchar2(255) := 'bucket-owner-full-control';

  -- get buckets
  function get_bucket_list return t_bucket_list;

  -- get buckets
  function get_bucket_tab return t_bucket_tab pipelined;
  
  -- create bucket
  procedure new_bucket (p_bucket_name in varchar2,
                        p_region in varchar2 := null);

  -- get bucket region
  function get_bucket_region (p_bucket_name in varchar2) return varchar2;

  -- get objects
  function get_object_list (p_bucket_name in varchar2,
                            p_prefix in varchar2 := null,
                            p_max_keys in number := null) return t_object_list;

  -- get objects
  function get_object_tab (p_bucket_name in varchar2,
                           p_prefix in varchar2 := null,
                           p_max_keys in number := null) return t_object_tab pipelined;

  -- get download URL
  function get_download_url (p_bucket_name in varchar2,
                             p_key in varchar2,
                             p_expiry_date in date) return varchar2;

  -- new object
  procedure new_object (p_bucket_name in varchar2,
                        p_key in varchar2,
                        p_object in blob,
                        p_content_type in varchar2,
                        p_acl in varchar2 := null);
                        
  -- delete object
  procedure delete_object (p_bucket_name in varchar2,
                           p_key in varchar2);

  -- get object
  function get_object (p_bucket_name in varchar2,
                       p_key in varchar2) return blob;

  -- delete bucket
  procedure delete_bucket (p_bucket_name in varchar2);

  -- get owner for an object
  function get_object_owner (p_bucket_name in varchar2,
                             p_key in varchar2) return t_owner;

  -- get grantees for an object
  function get_object_grantee_list (p_bucket_name in varchar2,
                                    p_key in varchar2) return t_grantee_list;

  -- get grantees for an object
  function get_object_grantee_tab (p_bucket_name in varchar2,
                                   p_key in varchar2) return t_grantee_tab pipelined;

  -- modify the access control list for an object
  procedure set_object_acl (p_bucket_name in varchar2,
                            p_key in varchar2,
                            p_acl in varchar2);

end amazon_aws_s3_pkg;
/

