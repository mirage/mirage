#include <sys/ioctl.h>

int __libc_tcdrain(int fd);
int __libc_tcdrain(int fd)
{
  return ioctl(fd, TCSBRK, 1);
}

int tcdrain(int fd) __attribute__((weak,alias("__libc_tcdrain")));
