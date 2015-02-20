
-- generate random test data of various types

select random_util_pkg.get_integer,
  random_util_Pkg.get_date,
  random_util_pkg.get_amount,
  random_util_pkg.get_file_type,
  random_util_pkg.get_file_name,
  random_util_pkg.get_mime_type,
  random_util_pkg.get_text (10,50) as some_text
from dual
connect by rownum <= 10

-- generate random user information

select random_util_pkg.get_person_name as person_name,
  random_util_pkg.get_value (t_str_array('super user', 'administrator', 'accountant', 'manager')) as user_type,
  random_util_pkg.get_password as password,
  random_util_pkg.get_date as last_login_date
from dual
connect by rownum <= 10

-- same as above, but with email address (matching the person's name)

select t.*,
  random_util_pkg.get_email_address (t_str_array('company1.example', 'company2.example', 'company3.example'), t.person_name) as email_address
from (
select random_util_pkg.get_person_name as person_name,
  random_util_pkg.get_value (t_str_array('super user', 'administrator', 'accountant', 'manager')) as user_type,
  random_util_pkg.get_password as password
from dual
connect by rownum <= 10) t

-- generate some data from the Sales department

select random_util_pkg.get_date as purchase_date,
  random_util_pkg.get_value (t_str_array('jacket', 'shoes', 'socks (3-pack)', 'hat')) as product_name,
  random_util_pkg.get_amount (10, 200) as purchase_amount,
  random_util_pkg.get_person_name as customer_name
from dual
connect by rownum <= 25



-- some not-so-serious generators, just for fun :-)

select random_util_pkg.get_buzzword,
  random_util_pkg.get_business_concept,
  random_util_pkg.get_wait_message,
  random_util_Pkg.get_error_message
from dual
connect by rownum <= 10
