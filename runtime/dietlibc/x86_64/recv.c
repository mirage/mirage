#include <sys/types.h>
#include <sys/socket.h>
#include <linuxnet.h>

int __libc_recv(int fd, void * buf, size_t n, int flags);
  /* shut up gcc warning about missing prototype */

int __libc_recv(int fd, void * buf, size_t n, int flags) {
  return recvfrom(fd, buf, n, flags, 0, 0);
}

int recv(int a, void * b, size_t c, int flags)
  __attribute__ ((weak, alias("__libc_recv")));
