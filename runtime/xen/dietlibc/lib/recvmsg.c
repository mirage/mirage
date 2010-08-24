#include <sys/socket.h>
#include <linuxnet.h>

extern int socketcall(int callno,long* args);

int __libc_recvmsg(int a, struct msghdr* msg, int flags);
int __libc_recvmsg(int a, struct msghdr* msg, int flags) {
  long args[] = { a, (long) msg, flags };
  return socketcall(SYS_RECVMSG, args);
}

int recvmsg(int a, struct msghdr *msg, int flags)
 __attribute__ ((weak,alias("__libc_recvmsg"))) ;
