#include <linuxnet.h>
#include <sys/socket.h>

extern int socketcall(int callno,long* args);

int __libc_getsockname(int a, void * b, int c);
int __libc_getsockname(int a, void * b, int c) {
  long args[] = { a, (long) b, c };
  return socketcall(SYS_GETSOCKNAME, args);
}

int getsockname(int a, struct sockaddr* b, socklen_t* c) __attribute__((weak,alias("__libc_getsockname")));
