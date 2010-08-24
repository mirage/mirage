#include <endian.h>
#include <sys/types.h>
#include <unistd.h>

size_t __libc_pwrite(int fd, void *buf, size_t count, off_t offset);
size_t __libc_pwrite(int fd, void *buf, size_t count, off_t offset) {
  return pwrite64(fd,buf,count,offset);
}

ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset) __attribute__((weak,alias("__libc_pwrite")));
