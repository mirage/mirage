#include <sys/types.h>
#include <linuxnet.h>

extern int socketcall(int callno,long* args);

int __libc_send(int a, const void * b, size_t c, int flags);
int __libc_send(int a, const void * b, size_t c, int flags) {
  long args[] = { a, (long) b, c, flags };
  return socketcall(SYS_SEND, args);
}

int send(int a, const void * b, size_t c, int flags)
  __attribute__ ((weak, alias("__libc_send")));
