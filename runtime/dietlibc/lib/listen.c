#include <linuxnet.h>
#include <sys/socket.h>

extern int socketcall(int callno,long* args);

int __libc_listen(int a, int b);
int __libc_listen(int a, int b) {
  long args[] = { a, b, 0 };
  return socketcall(SYS_LISTEN, args);
}

int listen(int s, int backlog) __attribute__((weak,alias("__libc_listen")));
