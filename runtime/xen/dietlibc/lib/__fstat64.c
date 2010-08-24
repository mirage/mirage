#include <errno.h>
#include "dietfeatures.h"
#ifdef WANT_LARGEFILE_BACKCOMPAT
#include <sys/stat.h>
#ifndef __NO_STAT64

extern int __dietlibc_fstat64(int __fd, struct stat64 *__buf);
extern void __stat64_cvt(const struct stat *src,struct stat64 *dest);

int fstat64(int __fd, struct stat64 *__buf) {
  if (__dietlibc_fstat64(__fd,__buf)) {
    struct stat temp;
    if (errno!=ENOSYS) return -1;
    if (fstat(__fd,&temp)) return -1;
    __stat64_cvt(&temp,__buf);
  }
  return 0;
}
#endif
#endif
