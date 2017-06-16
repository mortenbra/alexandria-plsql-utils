create or replace package hash_util_pkg as 

  /*
 
  Purpose: 
    Calculates SHA-1 and SHA-2 hashes.
    Pure PL/SQL implementation. Uses decimal caclulations, works very slow.
    Use DBMS_CRYPTO or external Java functions for quick hash calculation, whenever possible.
 
  Author: Vadim Dvorovenko

  Changes:
  Who     Date        Description
  ------  ----------  --------------------------------
  DVN     09.12.2014  Created
  DVN     26.11.2016  Formatting code for Alexandria library, BLOB verison
  DVN     27.11.2016  Fully rewritten process_bytes procedures.
  DVN     27.11.2016  Added SHA-224, SHA-384, SHA-512, SHA-512/256, SHA-512/224
 
  */
  
  subtype sha1_checksum_raw is raw(20);
  subtype sha224_checksum_raw is raw(28);
  subtype sha256_checksum_raw is raw(32);
  subtype sha384_checksum_raw is raw(48);
  subtype sha512_checksum_raw is raw(64);

  -- Raw versions. Max p_buffer length - 16384 bytes
  function sha1(p_buffer in raw) return sha1_checksum_raw;
  function sha224(p_buffer in raw) return sha224_checksum_raw;
  function sha256(p_buffer in raw) return sha256_checksum_raw;
  function sha384(p_buffer in raw) return sha384_checksum_raw;
  function sha512(p_buffer in raw) return sha512_checksum_raw;
  function sha512_224(p_buffer in raw) return sha224_checksum_raw;
  function sha512_256(p_buffer in raw) return sha256_checksum_raw;

  -- Blob versions.
  function sha1(p_buffer in blob) return sha1_checksum_raw;
  function sha224(p_buffer in blob) return sha224_checksum_raw;
  function sha256(p_buffer in blob) return sha256_checksum_raw;
  function sha384(p_buffer in blob) return sha384_checksum_raw;
  function sha512(p_buffer in blob) return sha512_checksum_raw;
  function sha512_224(p_buffer in blob) return sha224_checksum_raw;
  function sha512_256(p_buffer in blob) return sha256_checksum_raw;

  procedure unittest;

end hash_util_pkg;
/

