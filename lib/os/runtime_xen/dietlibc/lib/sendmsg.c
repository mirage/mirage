#include <sys/socket.h>
#include <linuxnet.h>

extern int socketcall(int callno,long* args);

int __libc_sendmsg(int a, const struct msghdr* msg, int flags);
int __libc_sendmsg(int a, const struct msghdr* msg, int flags) {
  long args[] = { a, (long) msg, flags };
  return socketcall(SYS_SENDMSG, args);
}

int sendmsg(int a, const struct msghdr *msg, int flags)
 __attribute__ ((weak,alias("__libc_sendmsg"))) ;
