#define _XOPEN_SOURCE
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdlib.h>

int unlockpt (int fd) {
  int foo=0;
  /* hehe, that one is easy */
  return (ioctl (fd, TIOCSPTLCK, &foo));
}
