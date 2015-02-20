create or replace package body random_util_pkg
as
 
  /*
 
  Purpose:      Package handles generation of random values
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  type t_word_table is table of varchar2(2000) index by binary_integer;
 
 
function get_text_from_word_list (p_words in t_word_table,
                                  p_min_length in number := null,
                                  p_max_length in number := null,
                                  p_separators in t_str_array := null) return varchar2
as
  l_min_length                   number := nvl(p_min_length, 10);
  l_max_length                   number := nvl(p_max_length, 255);
  l_desired_length               number;
  l_returnvalue                  string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      get random text
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  l_desired_length := get_integer (l_min_length, l_max_length);

  l_returnvalue := p_words(get_integer(1,p_words.count));
  
  while length(l_returnvalue) < l_desired_length loop
    l_returnvalue := l_returnvalue || get_value(nvl(p_separators, t_str_array(' '))) || p_words(get_integer(1,p_words.count));
  end loop;
  
  l_returnvalue := substr(l_returnvalue, 1, l_max_length);

  return l_returnvalue;
 
end get_text_from_word_list;


function get_integer (p_min_value in number := null,
                      p_max_value in number := null) return number
as
  l_returnvalue number;
begin
 
  /*
 
  Purpose:      get random integer
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  l_returnvalue := round(dbms_random.value(nvl(p_min_value,0),nvl(p_max_value,100)));
 
  return l_returnvalue;
 
end get_integer;


function get_date (p_from_date in date := null,
                   p_to_date in date := null) return date
as
  l_from_date    date := coalesce (p_from_date, sysdate - 1000);
  l_to_date      date := coalesce (p_to_date, sysdate + 1000);
  l_days_between number;
  l_returnvalue date;
begin
 
  /*
 
  Purpose:      get random date
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  l_days_between := round(l_to_date - l_from_date);
  
  -- add a decimal number to get random time part of the date
  l_returnvalue := l_from_date + get_amount (0, l_days_between);

  return l_returnvalue;
 
end get_date;
 
 
function get_amount (p_min_value in number := null,
                     p_max_value in number := null) return number
as
  l_returnvalue number;
begin
 
  /*
 
  Purpose:      get a random amount (money)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
 
  l_returnvalue := round(dbms_random.value(nvl(p_min_value,-20000),nvl(p_max_value,100000)),2);

  return l_returnvalue;
 
end get_amount;
 
 
function get_file_name (p_max_length in number := null,
                        p_file_type in varchar2 := null) return varchar2
as
  l_words                        t_word_table;
  l_returnvalue                  string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get a random file name
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  l_words(1) := get_integer(1,9999);
  l_words(2) := 'notes';
  l_words(3) := 'vacation';
  l_words(4) := 'tender';
  l_words(5) := 'confirmation';
  l_words(6) := 'manual';
  l_words(7) := 'guide';
  l_words(8) := 'worksheet';
  l_words(9) := 'compliance';
  l_words(10) := 'project';
  l_words(11) := 'city';
  l_words(12) := 'flight';
  l_words(13) := 'transport';
  l_words(14) := 'rockstar';
  l_words(15) := 'recipe';
  l_words(16) := 'traditional';
  l_words(17) := 'form';
  l_words(18) := 'template';
  l_words(19) := 'design';
  l_words(20) := 'comparison';
  l_words(21) := get_integer(1,100);
  l_words(22) := 'information';
  l_words(23) := 'IMPORTANT';
  l_words(24) := 'NICE';
  l_words(25) := 'temp';
  l_words(26) := 'draft ' || get_integer(1,10);

  l_returnvalue := get_text_from_word_list (l_words, 1, nvl(p_max_length, 30), t_str_array('_', ' ', '-', ', '));
  
  l_returnvalue := l_returnvalue || '.' || coalesce(p_file_type, get_file_type);
 
  return l_returnvalue;
 
end get_file_name;
 
 
function get_file_type return varchar2
as
  l_words       t_word_table;
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get a random file type
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
 
  l_words(1) := 'txt';
  l_words(2) := 'jpg';
  l_words(3) := 'jpeg';
  l_words(4) := 'gif';
  l_words(5) := 'png';
  l_words(6) := 'htm';
  l_words(7) := 'html';
  l_words(8) := 'xml';
  l_words(9) := 'csv';
  l_words(10) := 'doc';
  l_words(11) := 'docx';
  l_words(12) := 'xls';
  l_words(13) := 'xlsx';
  l_words(14) := 'ppt';
  l_words(15) := 'pptx';
  l_words(16) := 'js';
  
  l_returnvalue := l_words(get_integer(1,l_words.count));

  return l_returnvalue;
 
end get_file_type;
 
 
function get_mime_type return varchar2
as
  l_words       t_word_table;
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get a random mime type
 
  Remarks:      see http://www.iana.org/assignments/media-types/
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
 
  l_words(1) := 'text/plain';
  l_words(2) := 'text/css';
  l_words(3) := 'text/html';
  l_words(4) := 'text/xml';
  l_words(5) := 'application/pdf';
  l_words(6) := 'application/json';
  l_words(7) := 'application/xml';
  l_words(8) := 'application/zip';
  l_words(9) := 'audio/mpeg';
  l_words(10) := 'image/gif';
  l_words(11) := 'image/jpeg';
  l_words(12) := 'image/png';
  l_words(13) := 'multipart/form-data';
  l_words(14) := 'video/mpeg';
  
  l_returnvalue := l_words(get_integer(1,l_words.count));

  return l_returnvalue;
 
end get_mime_type;
 

function get_person_name (p_gender in varchar2 := null) return varchar2
as
  l_gender       varchar2(30) := p_gender;
  l_words0       t_word_table;
  l_words1       t_word_table;
  l_words2       t_word_table;
  l_words3       t_word_table;
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get random person name
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  l_words0(1) := 'male';
  l_words0(2) := 'female';
 
  l_words1(1) := 'Ali';
  l_words1(2) := 'Lukas';
  l_words1(3) := 'Noah';
  l_words1(4) := 'Lois';
  l_words1(5) := 'Arthur';
  l_words1(6) := 'Ivan';
  l_words1(7) := 'Lucas';
  l_words1(8) := 'Hugo';
  l_words1(9) := 'Lars';
  l_words1(10) := 'Thomas';
  l_words1(11) := 'Martin';
  l_words1(12) := 'Paul';
  l_words1(13) := 'Dimitrios';
  l_words1(14) := 'Ricardo';
  l_words1(15) := 'Tim';
  
  l_words2(1) := 'Marie';
  l_words2(2) := 'Hala';
  l_words2(3) := 'Elena';
  l_words2(4) := 'Charlotte';
  l_words2(5) := 'Victoria';
  l_words2(6) := 'Anna';
  l_words2(7) := 'Tereza';
  l_words2(8) := 'Heidi';
  l_words2(9) := 'Rakel';
  l_words2(10) := 'Emma';
  l_words2(11) := 'Violeta';
  l_words2(12) := 'Tatiana';
  l_words2(13) := 'Daniela';
  l_words2(14) := 'Julia';
  l_words2(15) := 'Anastasia';

  -- see http://en.wikipedia.org/wiki/Family_name
  l_words3(1) := 'Smith';
  l_words3(2) := 'Johnson';
  l_words3(3) := 'Williams';
  l_words3(4) := 'Garcia';
  l_words3(5) := 'Martinez';
  l_words3(6) := 'Young';
  l_words3(7) := 'Hernandez';
  l_words3(8) := 'Jordan';
  l_words3(9) := 'Larsen';
  l_words3(10) := 'Beach';
  l_words3(11) := 'Vang';
  l_words3(12) := 'Laurent';
  l_words3(13) := 'Blanc';
  l_words3(14) := 'Katz';
  l_words3(15) := 'Kovazevic';
  
  if l_gender is null then
    l_gender := l_words0(get_integer(1,l_words0.count));
  end if;
  
  if l_gender = 'male' then
    l_returnvalue := l_words1(get_integer(1,l_words1.count)) || ' ' || l_words3(get_integer(1,l_words3.count));
  else
    l_returnvalue := l_words2(get_integer(1,l_words2.count)) || ' ' || l_words3(get_integer(1,l_words3.count));
  end if;

  return l_returnvalue;
 
end get_person_name;
 
 
function get_email_address (p_mail_domains in t_str_array,
                            p_person_name in varchar2 := null) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get random email address
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  l_returnvalue := lower(replace(coalesce(p_person_name, get_person_name), ' ', '.')) || '@' || get_value (p_mail_domains);
 
  return l_returnvalue;
 
end get_email_address;
 
 
function get_text (p_min_length in number := null,
                   p_max_length in number := null,
                   p_language in varchar2 := null) return varchar2
as
  l_language                     varchar2(30) := nvl(p_language, 'latin');
  l_words                        t_word_table;
  l_returnvalue                  string_util_pkg.t_max_pl_varchar2;
begin
 
  /*
 
  Purpose:      get random text
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  if l_language = 'leet' then

    l_words(1) := 'teh';
    l_words(2) := 'pwned';
    l_words(3) := 'leet';
    l_words(4) := 'warez';
    l_words(5) := 'haxor';
    l_words(6) := 'j00';
    l_words(7) := 'uber';
    l_words(8) := 'w00t';
    l_words(9) := 'skillz';
    l_words(10) := 'n00b';
    l_words(11) := 'pr0n';
    l_words(12) := 'LOL';
    l_words(13) := 'suxorz';
    
  else 

    l_words(1) := 'lorem';
    l_words(2) := 'ipsum';
    l_words(3) := 'dolor';
    l_words(4) := 'sit';
    l_words(5) := 'amet';
    l_words(6) := 'consectetur';
    l_words(7) := 'adipiscing';
    l_words(8) := 'elit';
    l_words(9) := 'in';
    l_words(10) := 'venenatis';
    l_words(11) := 'facilisis';
    l_words(12) := 'augue';
    l_words(13) := 'sed';
    l_words(14) := 'vehicula';
    l_words(15) := 'vestibulum';
    l_words(16) := 'gravida';
    l_words(17) := 'justo';
    l_words(18) := 'ac';
    l_words(19) := 'justo';
    l_words(20) := 'posuere';
    l_words(21) := 'blandit';
    l_words(22) := 'suspendisse';
    l_words(23) := 'quis';
    l_words(24) := 'dui';
    l_words(25) := 'elit';
    l_words(26) := 'vitae';
    l_words(27) := 'luctus';
    l_words(28) := 'mauris';
    l_words(29) := 'ut';
    l_words(30) := 'sit';
    l_words(31) := 'amet';
    l_words(32) := 'erat';
    l_words(33) := 'sapien';
    l_words(34) := 'integer';
    l_words(35) := 'nec';
    l_words(36) := 'lacus';
    l_words(37) := 'nec';
    l_words(38) := 'enim';
    l_words(39) := 'facilisis';
    l_words(40) := 'euismod';
    l_words(41) := 'curabitur';
    l_words(42) := 'porttitor';
    l_words(43) := 'orci';
    l_words(44) := 'at';
    l_words(45) := 'massa';
    l_words(46) := 'blandit';
    l_words(47) := 'sit';
    l_words(48) := 'amet';
    l_words(49) := 'varius';
    l_words(50) := 'diam';
    
  end if;
  
  l_returnvalue := get_text_from_word_list (l_words, p_min_length, p_max_length, t_str_array(' ', ', '));

  return l_returnvalue;
 
end get_text;
 
 
function get_buzzword return varchar2
as
  l_words       t_word_table;
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get random buzzword
 
  Remarks:      see http://en.wikipedia.org/wiki/List_of_buzzwords
                see http://programmers.stackexchange.com/questions/38505/most-overhyped-software-engineering-technologies-and-concepts-of-the-last-20-year
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
 
  l_words(1) := 'SOA';
  l_words(2) := 'cloud';
  l_words(3) := 'mobile';
  l_words(4) := 'tablet';
  l_words(5) := 'iPhone';
  l_words(6) := 'web 2.0';
  l_words(7) := 'Facebook';
  l_words(8) := 'social media';
  l_words(9) := 'NoSQL';
  l_words(10) := 'agile';
  l_words(11) := 'UML';
  l_words(12) := 'Sharepoint';
  l_words(13) := 'test driven design';
  l_words(14) := 'Silverlight';
  
  l_returnvalue := l_words(get_integer(1,l_words.count));

  return l_returnvalue;
 
end get_buzzword;


function get_business_concept return varchar2
as
  l_words1       t_word_table;
  l_words2       t_word_table;
  l_words3       t_word_table;
  l_words4       t_word_table;
  l_words5       t_word_table;
  l_words6       t_word_table;
  l_words7       t_word_table;
  
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get random business concept
 
  Remarks:      "Completely innovate stand-alone data rather than next-generation ideas." (!)
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
 
  l_words1(1) := 'seamlessly';
  l_words1(2) := 'globally';
  l_words1(3) := 'holistically';
  l_words1(4) := 'assertively';
  l_words1(5) := 'compellingly';
  l_words1(6) := 'quickly';
  l_words1(7) := 'authoritatively';
  l_words1(8) := 'interactively';
  l_words1(9) := 'enthusiastically';
  l_words1(10) := 'appropriately';
  l_words1(11) := 'completely';
  l_words1(12) := 'credibly';
  l_words1(13) := 'dynamically';
  l_words1(14) := 'collaboratively';
  l_words1(15) := 'synergistically';
  
  l_words2(1) := 'empower';
  l_words2(2) := 'scale';
  l_words2(3) := 'harness';
  l_words2(4) := 'evolve';
  l_words2(5) := 'revolutionize';
  l_words2(6) := 'restore';
  l_words2(7) := 'leverage';
  l_words2(8) := 'innovate';
  l_words2(9) := 'e-enable';
  l_words2(10) := 'maintain';
  l_words2(11) := 'negotiate';
  l_words2(12) := 'reconceptualize';
  l_words2(13) := 'provide';
  l_words2(14) := 'plagiarize';
  l_words2(15) := 'reinvent';

  l_words3(1) := 'dynamic';
  l_words3(2) := 'front-end';
  l_words3(3) := 'business';
  l_words3(4) := 'extensible';
  l_words3(5) := 'intensive';
  l_words3(6) := 'robust';
  l_words3(7) := 'web-enabled';
  l_words3(8) := 'stand-alone';
  l_words3(9) := 'scalable';
  l_words3(10) := 'sticky';
  l_words3(11) := 'worldwide';
  l_words3(12) := 'B2B';
  l_words3(13) := 'state-of-the-art';
  l_words3(14) := 'cost-effective';
  l_words3(15) := 'interdependent';

  l_words4(1) := 'communities';
  l_words4(2) := 'ideas';
  l_words4(3) := 'data';
  l_words4(4) := 'ROI';
  l_words4(5) := 'human capital';
  l_words4(6) := 'convergence';
  l_words4(7) := 'products';
  l_words4(8) := 'markets';
  l_words4(9) := 'potentialities';
  l_words4(10) := 'technology';
  l_words4(11) := 'leadership';
  l_words4(12) := 'focus areas';
  l_words4(13) := 'content';
  l_words4(14) := 'opportunities';
  l_words4(15) := 'outside-the-box thinking';

  l_words5(1) := 'with';
  l_words5(2) := 'through';
  l_words5(3) := 'via';
  l_words5(4) := 'rather than';
  l_words5(5) := 'without';
  l_words5(6) := 'for';
  l_words5(7) := 'before';
  l_words5(8) := 'after';
  l_words5(9) := 'and';
  l_words5(10) := 'using';

  l_words6(1) := 'clicks-and-mortar';
  l_words6(2) := 'next-generation';
  l_words6(3) := 'resource-maximizing';
  l_words6(4) := 'end-to-end';
  l_words6(5) := 'visionary';
  l_words6(6) := 'intuitive';
  l_words6(7) := 'e-business';
  l_words6(8) := 'tactical';
  l_words6(9) := 'strategic';
  l_words6(10) := 'process-centric';
  l_words6(11) := 'impactful';
  l_words6(12) := 'client-based';
  l_words6(13) := 'error-free';
  l_words6(14) := 'magnetic';
  l_words6(15) := 'timely';

  l_words7(1) := 'testing procedures';
  l_words7(2) := 'web services';
  l_words7(3) := 'meta-services';
  l_words7(4) := 'e-products';
  l_words7(5) := 'portals';
  l_words7(6) := 'sources';
  l_words7(7) := 'expertise';
  l_words7(8) := 'markets';
  l_words7(9) := 'ideas';
  l_words7(10) := 'innovation';
  l_words7(11) := 'best practices';
  l_words7(12) := 'architecture';
  l_words7(13) := 'alignment';
  l_words7(14) := 'benefits';
  l_words7(15) := 'experiences';

  l_returnvalue := initcap(l_words1(get_integer(1,l_words1.count))) || ' ' ||
                   l_words2(get_integer(1,l_words2.count)) || ' ' ||
                   l_words3(get_integer(1,l_words3.count)) || ' ' ||
                   l_words4(get_integer(1,l_words4.count)) || ' ' ||
                   l_words5(get_integer(1,l_words5.count)) || ' ' ||
                   l_words6(get_integer(1,l_words6.count)) || ' ' ||
                   l_words7(get_integer(1,l_words7.count)) || '.';
                   
  return l_returnvalue;
 
end get_business_concept;


function get_wait_message return varchar2
as
  l_words1       t_word_table;
  l_words2       t_word_table;
  l_words3       t_word_table;
  l_returnvalue  string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get a random wait message
 
  Remarks:      see http://stackoverflow.com/questions/182112/what-are-some-funny-loading-statements-to-keep-users-amused
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
 
  l_words1(1) := 'recalibrating';
  l_words1(2) := 'analyzing';
  l_words1(3) := 'finalizing';
  l_words1(4) := 'acquiring';
  l_words1(5) := 'locking';
  l_words1(6) := 'deciphering';
  l_words1(7) := 'extracting';
  l_words1(8) := 'binding';
  l_words1(9) := 'loading';
  l_words1(10) := 'preparing';

  l_words2(1) := 'flux';
  l_words2(2) := 'data';
  l_words2(3) := 'spline';
  l_words2(4) := 'storage';
  l_words2(5) := 'plasma';
  l_words2(6) := 'laser';
  l_words2(7) := 'cache';
  l_words2(8) := 'internal';
  l_words2(9) := 'external';
  l_words2(10) := 'relational';

  l_words3(1) := 'capacitor';
  l_words3(2) := 'conductor';
  l_words3(3) := 'assembler';
  l_words3(4) := 'disk';
  l_words3(5) := 'detector';
  l_words3(6) := 'post-processor';
  l_words3(7) := 'pre-processor';
  l_words3(8) := 'integrator';
  l_words3(9) := 'grid';
  l_words3(10) := 'area';

  l_returnvalue := initcap(l_words1(get_integer(1,l_words1.count))) || ' ' ||
                   l_words2(get_integer(1,l_words2.count)) || ' ' ||
                   l_words3(get_integer(1,l_words3.count));

  return l_returnvalue;
 
end get_wait_message;
 
 
function get_error_message return varchar2
as
  l_words        t_word_table;
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get a random error message
 
  Remarks:      http://stackoverflow.com/questions/238079/funny-or-weird-error-messages-from-a-development-environment-application
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */

  l_words(1) := 'Catastrophic failure';
  l_words(2) := '"null" is null or not an object';
  l_words(3) := 'ORA-' || get_integer(10000,99999);
  l_words(4) := 'Keyboard not found. Press F1 to continue.';
  l_words(5) := 'The error message cannot be displayed';
  l_words(6) := 'Unknown error';
  l_words(7) := 'Runtime error ' || get_integer (-10, 100);
  l_words(8) := 'Guru Meditation #' || get_integer (10000000);
  l_words(9) :=  get_integer(500,599) || ' Internal Server Error';
  l_words(10) :=  'Unhandled exception in matrix$dll';
  l_words(11) := 'Error: expected type (int, int, int) but got type (int, int, int).';
  l_words(12) := 'Normal, successful completion.';
  
  l_returnvalue := l_words(get_integer(1,l_words.count));
 
  return l_returnvalue;
 
end get_error_message;


function get_value (p_values in t_str_array) return varchar2
as
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get a random value
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */

  l_returnvalue := p_values(get_integer(1,p_values.count));
 
  return l_returnvalue;
 
end get_value;


function get_password (p_length in number := null) return varchar2
as
  l_length      number := nvl(p_length, 8);
  l_char        varchar2(1);
  l_vowel       boolean := false;
  l_returnvalue string_util_pkg.t_max_db_varchar2;
begin
 
  /*
 
  Purpose:      get a random password
 
  Remarks:      uses a combination of consonants and vowels which are easier to pronounce/remember than totally random passwords  
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  for i in 1 .. least(l_length,255) loop
  
    if not l_vowel then
      -- no C, X, Z, or Q, thanks!
      l_char := get_value (t_str_array('b', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'r', 's', 't', 'v', 'w', 'y'));
      l_returnvalue := l_returnvalue || l_char;
      -- switch to vowel for next iteration
      l_vowel := true;
    else
      l_char := get_value (t_str_array('a', 'e', 'i', 'o', 'u'));
      l_returnvalue := l_returnvalue || l_char;
      -- switch back to consonant
      l_vowel := false;
    end if;

  end loop;
  
  return l_returnvalue;
 
end get_password;


end random_util_pkg;
/
 


