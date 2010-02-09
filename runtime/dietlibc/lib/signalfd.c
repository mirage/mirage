#include <signal.h>
#include <errno.h>
#include <sys/signalfd.h>

extern int __signalfd(int fd,const sigset_t* mask,size_t nsig);

int signalfd(int fd,const sigset_t* mask,int flags) {
  if (flags) {	/* bizarre glibc bullshit */
    errno=EINVAL;
    return -1;
  }
  return __signalfd(fd,mask,_NSIG/8);
}
