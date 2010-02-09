#include <linuxnet.h>

extern int socketcall(int callno,long* args);

int __libc_socket(int a, int b, int c);
int __libc_socket(int a, int b, int c) {
  long args[] = { a, b, c };
  return socketcall(SYS_SOCKET, args);
}

int socket(int a,int b,int c) __attribute__((weak,alias("__libc_socket")));
