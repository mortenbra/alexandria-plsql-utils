create or replace package body regexp_util_pkg
as

  /*

  Purpose:    Package handles regular expressions

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     13.10.2009  Created

  */

function match (p_str in clob,
                p_pattern in varchar2) return t_str_array pipelined
as
  l_val varchar2(4000);
  l_idx pls_integer;
  l_cnt pls_integer := 1;
begin

  /*

  Purpose:    return pattern matches as (pipelined) array

  Remarks:    typical usage: select column_value from table(regexp_util_pkg.match('my string', 'my pattern'))

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     13.10.2009  Created

  */

  if p_str is not null then
    
    loop
      l_val := regexp_substr(p_str, p_pattern, 1, l_cnt);
      if l_val is null then
        exit;
      else
        l_cnt := l_cnt + 1;
        pipe row (l_val);
      end if;
    end loop;
  
  end if;
  
  return;

end match;


end regexp_util_pkg;
/

