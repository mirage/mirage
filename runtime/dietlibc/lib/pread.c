#include <endian.h>
#include <sys/types.h>
#include <unistd.h>

ssize_t __libc_pread(int fd, void *buf, size_t count, off_t offset);
ssize_t __libc_pread(int fd, void *buf, size_t count, off_t offset) {
  return pread64(fd,buf,count,offset);
}

ssize_t pread(int fd, void *buf, size_t count, off_t offset) __attribute__((weak,alias("__libc_pread")));
