CREATE OR REPLACE PACKAGE ftp_util_pkg
AS

-- --------------------------------------------------------------------------
-- Name         : http://www.oracle-base.com/dba/miscellaneous/ftp.pks
-- Author       : DR Timothy S Hall
-- Description  : Basic FTP API. For usage notes see:
--                  http://www.oracle-base.com/articles/misc/FTPFromPLSQL.php
-- Requirements : UTL_TCP
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   14-AUG-2003  Tim Hall  Initial Creation
--   10-MAR-2004  Tim Hall  Add convert_crlf procedure.
--                          Make get_passive function visible.
--                          Added get_direct and put_direct procedures.
--   03-OCT-2006  Tim Hall  Add list, rename, delete, mkdir, rmdir procedures.
--   15-Jan-2008  Tim Hall  login: Include timeout parameter (suggested by Dmitry Bogomolov).
--   12-Jun-2008  Tim Hall  get_reply: Moved to pakage specification.
--   22-Apr-2009  Tim Hall  nlst: Added to return list of file names only (suggested by Julian and John Duncan)
-- --------------------------------------------------------------------------

  TYPE t_string_table IS TABLE OF VARCHAR2(32767);
  
  FUNCTION login (p_host    IN  VARCHAR2,
                  p_port    IN  VARCHAR2,
                  p_user    IN  VARCHAR2,
                  p_pass    IN  VARCHAR2,
                  p_timeout IN  NUMBER := NULL) RETURN UTL_TCP.connection;
  
  FUNCTION get_passive (p_conn  IN OUT NOCOPY  UTL_TCP.connection) RETURN UTL_TCP.connection;
  
  PROCEDURE logout (p_conn   IN OUT NOCOPY  UTL_TCP.connection,
                    p_reply  IN             BOOLEAN := TRUE);
  
  PROCEDURE send_command (p_conn     IN OUT NOCOPY  UTL_TCP.connection,
                          p_command  IN             VARCHAR2,
                          p_reply    IN             BOOLEAN := TRUE);
  
  PROCEDURE get_reply (p_conn  IN OUT NOCOPY  UTL_TCP.connection);
  
  FUNCTION get_local_ascii_data (p_dir   IN  VARCHAR2,
                                 p_file  IN  VARCHAR2) RETURN CLOB;
  
  FUNCTION get_local_binary_data (p_dir   IN  VARCHAR2,
                                  p_file  IN  VARCHAR2) RETURN BLOB;
  
  FUNCTION get_remote_ascii_data (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                                  p_file  IN             VARCHAR2) RETURN CLOB;
  
  FUNCTION get_remote_binary_data (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                                   p_file  IN             VARCHAR2) RETURN BLOB;
  
  PROCEDURE put_local_ascii_data (p_data  IN  CLOB,
                                  p_dir   IN  VARCHAR2,
                                  p_file  IN  VARCHAR2);
  
  PROCEDURE put_local_binary_data (p_data  IN  BLOB,
                                   p_dir   IN  VARCHAR2,
                                   p_file  IN  VARCHAR2);
  
  PROCEDURE put_remote_ascii_data (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                                   p_file  IN             VARCHAR2,
                                   p_data  IN             CLOB);
  
  PROCEDURE put_remote_binary_data (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                                    p_file  IN             VARCHAR2,
                                    p_data  IN             BLOB);
  
  PROCEDURE get (p_conn       IN OUT NOCOPY  UTL_TCP.connection,
                 p_from_file  IN             VARCHAR2,
                 p_to_dir     IN             VARCHAR2,
                 p_to_file    IN             VARCHAR2);
  
  PROCEDURE put (p_conn       IN OUT NOCOPY  UTL_TCP.connection,
                 p_from_dir   IN             VARCHAR2,
                 p_from_file  IN             VARCHAR2,
                 p_to_file    IN             VARCHAR2);
  
  PROCEDURE get_direct (p_conn       IN OUT NOCOPY  UTL_TCP.connection,
                        p_from_file  IN             VARCHAR2,
                        p_to_dir     IN             VARCHAR2,
                        p_to_file    IN             VARCHAR2);
  
  PROCEDURE put_direct (p_conn       IN OUT NOCOPY  UTL_TCP.connection,
                        p_from_dir   IN             VARCHAR2,
                        p_from_file  IN             VARCHAR2,
                        p_to_file    IN             VARCHAR2);
  
  PROCEDURE help (p_conn  IN OUT NOCOPY  UTL_TCP.connection);
  
  PROCEDURE ascii (p_conn  IN OUT NOCOPY  UTL_TCP.connection);
  
  PROCEDURE binary (p_conn  IN OUT NOCOPY  UTL_TCP.connection);
  
  PROCEDURE list (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                  p_dir   IN             VARCHAR2,
                  p_list  OUT            t_string_table);
  
  PROCEDURE nlst (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                  p_dir   IN             VARCHAR2,
                  p_list  OUT            t_string_table);
  
  PROCEDURE rename (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                    p_from  IN             VARCHAR2,
                    p_to    IN             VARCHAR2);
  
  PROCEDURE delete (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                    p_file  IN             VARCHAR2);
  
  PROCEDURE mkdir (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                   p_dir   IN             VARCHAR2);
  
  PROCEDURE rmdir (p_conn  IN OUT NOCOPY  UTL_TCP.connection,
                   p_dir   IN             VARCHAR2);
  
  PROCEDURE convert_crlf (p_status  IN  BOOLEAN);

END ftp_util_pkg;
/


