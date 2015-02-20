-- read file from disk, encrypt it, and save it
-- note that the key must be exactly 32 characters (bytes) long

declare
  l_blob blob;
  l_enc  blob;
begin
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'my_pdf.pdf');
  l_enc := crypto_util_pkg.encrypt_aes256 (l_blob, '12345678901234567890123456789012');
  file_util_pkg.save_blob_to_file('DEVTEST_TEMP_DIR', 'my_encrypted_pdf.xxx', l_enc);
end;

-- read encrypted file from disk, decrypt it, and save it
-- note that the key must be exactly 32 characters (bytes) long

declare
  l_blob blob;
  l_enc  blob;
begin
  l_blob := file_util_pkg.get_blob_from_file ('DEVTEST_TEMP_DIR', 'my_encrypted_pdf.xxx');
  l_enc := crypto_util_pkg.decrypt_aes256 (l_blob, '12345678901234567890123456789012');
  file_util_pkg.save_blob_to_file('DEVTEST_TEMP_DIR', 'my_decrypted_pdf.pdf', l_enc);
end;
