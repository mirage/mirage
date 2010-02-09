#include <linuxnet.h>

extern int socketcall(int callno,long* args);

int __libc_socketpair(int a, int type, int protocol, int sv[2]);
int __libc_socketpair(int a, int type, int protocol, int sv[2]) {
  long args[] = { a, type, protocol, (long)sv };
  return socketcall(SYS_SOCKETPAIR, args);
}

int socketpair(int d, int type, int protocol, int sv[2])
  __attribute__((weak,alias("__libc_socketpair")));
