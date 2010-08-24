#include <linuxnet.h>

extern int socketcall(int callno,long* args);

int __libc_connect(int a, void * b, int c);
int __libc_connect(int a, void * b, int c) {
  long args[] = { a, (long) b, c };
  return socketcall(SYS_CONNECT, args);
}

int connect(int a, void * b, int c) __attribute__((weak,alias("__libc_connect")));
