
-- general-purpose SQL types


create type t_str_array as table of varchar2(4000);
/

create type t_date_array as table of date;
/

create type t_num_array as table of number;
/


create type t_name_value_pair as object (
  name          varchar2(255),
  value_string  varchar2(4000),
  value_number  number,
  value_date    date
);
/

create type t_dictionary as table of t_name_value_pair;
/

-- types for CSV parsing

create type t_csv_line as object (
  line_number  number,
  line_raw     varchar2(4000),
  c001         varchar2(4000),
  c002         varchar2(4000),
  c003         varchar2(4000),
  c004         varchar2(4000),
  c005         varchar2(4000),
  c006         varchar2(4000),
  c007         varchar2(4000),
  c008         varchar2(4000),
  c009         varchar2(4000),
  c010         varchar2(4000),
  c011         varchar2(4000),
  c012         varchar2(4000),
  c013         varchar2(4000),
  c014         varchar2(4000),
  c015         varchar2(4000),
  c016         varchar2(4000),
  c017         varchar2(4000),
  c018         varchar2(4000),
  c019         varchar2(4000),
  c020         varchar2(4000)
);
/

create type t_csv_tab as table of t_csv_line;
/

