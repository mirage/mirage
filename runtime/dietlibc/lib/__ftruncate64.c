#include <errno.h>
#include "dietfeatures.h"
#ifdef WANT_LARGEFILE_BACKCOMPAT
#include <sys/stat.h>
#include "syscalls.h"
#include <unistd.h>
#ifndef __NO_STAT64
#ifdef __NR_ftruncate64

extern int __dietlibc_ftruncate64(int fd, loff_t o);

int ftruncate64(int fd, loff_t o) {
  int tmp;
  if ((tmp=__dietlibc_ftruncate64(fd,o))==-1) {
    if (errno!=ENOSYS) return -1;
    if (o>0x7fffffff) { errno=EOVERFLOW; return -1; }
    return ftruncate(fd,o);
  }
  return tmp;
}
#endif
#endif
#endif
