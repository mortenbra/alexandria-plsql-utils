-- email validation

declare
  l_validation boolean;
begin
  debug_pkg.debug_on;
  l_validation := validation_util_pkg.is_valid_email ('someone@somewhere.net');
  debug_pkg.print('validation result (should be true)', l_validation);
  l_validation := validation_util_pkg.is_valid_email ('someone');
  debug_pkg.print('validation result (should be false)', l_validation);
  l_validation := validation_util_pkg.is_valid_email ('someone@');
  debug_pkg.print('validation result (should be false)', l_validation);
  l_validation := validation_util_pkg.is_valid_email ('someone@sdfsdf');
  debug_pkg.print('validation result (should be false)', l_validation);
  l_validation := validation_util_pkg.is_valid_email ('someone@sfdsf.safdsfsf');
  debug_pkg.print('validation result (should be false)', l_validation);
  l_validation := validation_util_pkg.is_valid_email ('someone@dsfsfd.sdf;sdfsfs');
  debug_pkg.print('validation result (should be false)', l_validation);
end;



-- email list validation


declare
  l_validation boolean;
begin
  debug_pkg.debug_on;
  l_validation := validation_util_pkg.is_valid_email_list ('someone@somewhere.net');
  debug_pkg.print('validation result (should be true)', l_validation);
  l_validation := validation_util_pkg.is_valid_email_list ('user1@somewhere.net;user2@somewhere.net');
  debug_pkg.print('validation result (should be true)', l_validation);
  l_validation := validation_util_pkg.is_valid_email_list ('sdfsff dsfsfsdfs ; sdfsf @');
  debug_pkg.print('validation result (should be false)', l_validation);
  l_validation := validation_util_pkg.is_valid_email_list ('user1@somewhere.net;user2@somewhere.net;sdfsff');
  debug_pkg.print('validation result (should be false)', l_validation);
end;

