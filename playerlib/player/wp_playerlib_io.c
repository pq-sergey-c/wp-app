static int write_to_file(const char *src, int dst_fd, const char *mode) {
  FILE *dst_file = fdopen(dup(dst_fd), mode);
  if (dst_file == NULL) {
    return -1;
  }
  FILE *src_file = fopen(src, "rb");
  if (src_file == NULL) {
    fclose(dst_file);
    return -2;
  }
  char buf[4096];
  size_t n;
  while ((n = fread(buf, 1, sizeof(buf), src_file)) > 0) {
    if (fwrite(buf, 1, n, dst_file) != n) {
      fclose(src_file);
      fclose(dst_file);
      return -3;
    }
  }
  fflush(dst_file);
  fclose(src_file);
  fclose(dst_file);
  return 0;
}

int copy_file(const char *src, int dst_fd) {
  return write_to_file(src, dst_fd, "wb");
}

int append_to_file(const char *src, int dst_fd) {
  return write_to_file(src, dst_fd, "ab"); 
}
