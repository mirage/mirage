#include <linuxnet.h>
#include <sys/socket.h>

extern int socketcall(int callno,long* args);

int __libc_getsockopt(int a, int b, int c, void *d, int e);
int __libc_getsockopt(int a, int b, int c, void *d, int e) {
  long args[] = { a, b, c, (long)d, e };
  return socketcall(SYS_GETSOCKOPT, args);
}

int getsockopt(int s, int level, int optname, void * optval, socklen_t *optlen) __attribute__((weak,alias("__libc_getsockopt")));
