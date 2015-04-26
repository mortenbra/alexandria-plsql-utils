create or replace package amazon_aws_auth_pkg
as

  /*

  Purpose:   PL/SQL wrapper package for Amazon AWS authentication API

  Remarks:   inspired by the whitepaper "Building an Amazon S3 Client with Application Express 4.0" by Jason Straub
             see http://jastraub.blogspot.com/2011/01/building-amazon-s3-client-with.html

             dependencies: owner of this package needs execute on dbms_crypto

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     09.01.2011  Created

  */

  -- get "Authorization" (actually authentication) header string
  function get_auth_string (p_string in varchar2) return varchar2;

  -- get signature string
  function get_signature (p_string in varchar2) return varchar2;

  -- get AWS access key ID
  function get_aws_id return varchar2;

  -- get date string
  function get_date_string (p_date in date := sysdate) return varchar2;

  -- get epoch (number of seconds since January 1, 1970)
  function get_epoch (p_date in date) return number;

  -- set AWS access key id
  procedure set_aws_id (p_aws_id in varchar2);

  -- set AWS secret key
  procedure set_aws_key (p_aws_key in varchar2);

  -- set GMT offset
  procedure set_gmt_offset (p_gmt_offset in number);

  -- initialize package for use
  procedure init (p_aws_id in varchar2,
                  p_aws_key in varchar2,
                  p_gmt_offset in number := NULL);

end amazon_aws_auth_pkg;
/
