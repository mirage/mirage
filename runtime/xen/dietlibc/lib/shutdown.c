#include <linuxnet.h>
#include <sys/socket.h>

extern int socketcall(int callno,long* args);

int __libc_shutdown(int s, int how);
int __libc_shutdown(int s, int how) {
  long args[] = { s, (long) how, 0 };
  return socketcall(SYS_SHUTDOWN, args);
}

int shutdown(int s, int how) __attribute__((weak,alias("__libc_shutdown")));
