create or replace package regexp_util_pkg
as

  /*

  Purpose:    Package handles regular expressions

  Remarks:    see http://docs.oracle.com/cd/B19306_01/appdev.102/b14251/adfns_regexp.htm#i1007670

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     13.10.2009  Created

  */

  g_exp_bind_vars                constant varchar2(255) := ':\w+';
  g_exp_hyperlinks               constant varchar2(255) := '<a href="[^"]+">[^<]+</a>';
  g_exp_ip_addresses             constant varchar2(255) := '(\d{1,3}\.){3}\d{1,3}';
  g_exp_email_addresses          constant varchar2(255) := '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$';
  g_exp_email_address_list       constant varchar2(255) := '^((\s*[a-zA-Z0-9\._%-]+@[a-zA-Z0-9\.-]+\.[a-zA-Z]{2,4}\s*[,;:]){1,100}?)?(\s*[a-zA-Z0-9\._%-]+@[a-zA-Z0-9\.-]+\.[a-zA-Z]{2,4})*$';
  g_exp_double_words             constant varchar2(255) := ' ([A-Za-z]+) \1';
  g_exp_cc_visa                  constant varchar2(255) := '^4[0-9]{12}(?:[0-9]{3})?$';
  g_exp_square_brackets          constant varchar2(255) := '\[(.*?)\]';
  g_exp_curly_brackets           constant varchar2(255) := '{(.*?)}';
  g_exp_square_or_curly_brackets constant varchar2(255) := '\[.*?\]|\{.*?\}';

  -- return pattern matches as (pipelined) array
  function match (p_str in clob,
                  p_pattern in varchar2) return t_str_array pipelined;

end regexp_util_pkg;
/

