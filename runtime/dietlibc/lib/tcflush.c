#include <sys/ioctl.h>

int __libc_tcflush(int fd, int queue_selector);
int __libc_tcflush(int fd, int queue_selector)
{
  return ioctl(fd, TCFLSH, queue_selector);
}

int tcflush(int fd) __attribute__((weak,alias("__libc_tcflush")));
