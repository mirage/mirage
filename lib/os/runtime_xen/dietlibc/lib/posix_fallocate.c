#define _GNU_SOURCE
#define _XOPEN_SOURCE 600
#include <fcntl.h>

int posix_fallocate(int fd, off64_t offset, off64_t len) {
  return fallocate(fd,0,offset,len);
}
