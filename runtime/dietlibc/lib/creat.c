#include <fcntl.h>

int __libc_creat(const char *file,mode_t mode);
int __libc_creat(const char *file,mode_t mode) {
  return open(file,O_WRONLY|O_CREAT|O_TRUNC,mode);
}
int creat(const char *file,mode_t mode) __attribute__((weak,alias("__libc_creat")));
