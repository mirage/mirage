#include "dietfeatures.h"
#include <errno.h>
#ifdef WANT_LARGEFILE_BACKCOMPAT
#include <sys/stat.h>
#include "syscalls.h"
#include <unistd.h>
#ifndef __NO_STAT64
#ifdef __NR_truncate64

extern int __dietlibc_truncate64(const char* f, loff_t o);

int truncate64(const char* f, loff_t o) {
  int tmp;
  if ((tmp=__dietlibc_truncate64(f,o))==-1) {
    if (errno!=ENOSYS) return -1;
    if (o>0x7fffffff) { errno=EOVERFLOW; return -1; }
    return truncate(f,o);
  }
  return tmp;
}
#endif
#endif
#endif
