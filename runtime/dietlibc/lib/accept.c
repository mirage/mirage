#include <linuxnet.h>

extern int socketcall(int callno,long* args);

int __libc_accept(int a, void * addr, void * addr2);

int __libc_accept(int a, void * addr, void * addr2) {
  long args[] = { a, (long) addr, (long) addr2 };
  return socketcall(SYS_ACCEPT, args);
}

int accept(int a, void * addr, void * addr2) __attribute__((weak,alias("__libc_accept")));
