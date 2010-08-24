#include <linuxnet.h>
#include <sys/socket.h>

extern int socketcall(int callno,long* args);

int __libc_getpeername(int a, void * b, int *c);
int __libc_getpeername(int a, void * b, int *c) {
  long args[] = { a, (long) b, (long) c };
  return socketcall(SYS_GETPEERNAME, args);
}

int getpeername(int a, struct sockaddr* b, socklen_t *c) __attribute__((weak,alias("__libc_getpeername")));
