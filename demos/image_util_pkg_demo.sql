-- check if given file is actually an image

declare
  l_is_image boolean;
begin
  debug_pkg.debug_on;
  l_is_image := image_util_pkg.is_image (file_util_pkg.get_blob_from_file('DEVTEST_TEMP_DIR', 'some_image.jpg'));
  debug_pkg.print('result (should be true)', l_is_image);
  l_is_image := image_util_pkg.is_image (file_util_pkg.get_blob_from_file('DEVTEST_TEMP_DIR', 'some_text_file.txt'));
  debug_pkg.print('result (should be false)', l_is_image);
  l_is_image := image_util_pkg.is_image (file_util_pkg.get_blob_from_file('DEVTEST_TEMP_DIR', 'image74.png'), p_format => image_util_pkg.g_format_gif);
  debug_pkg.print('result (should be false)', l_is_image);
end;


-- get image info

declare
  l_info image_util_pkg.t_image_info;
begin
  debug_pkg.debug_on;
  l_info := image_util_pkg.get_image_info (file_util_pkg.get_blob_from_file('DEVTEST_TEMP_DIR', 'some_image.jpg'));
  debug_pkg.printf('type = %1, height = %2, width = %3', l_info.type, l_info.height, l_info.width);
end;




