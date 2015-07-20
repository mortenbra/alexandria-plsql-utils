
set scan off;


prompt Creating AMAZON package specifications

@../ora/amazon_aws_auth_pkg.pks
@../ora/amazon_aws_s3_pkg.pks

prompt Creating AMAZON package bodies

@../ora/amazon_aws_auth_pkg.pkb
@../ora/amazon_aws_s3_pkg.pkb


prompt Done!

