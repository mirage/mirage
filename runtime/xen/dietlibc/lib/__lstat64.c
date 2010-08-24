#include <errno.h>
#include "dietfeatures.h"
#ifdef WANT_LARGEFILE_BACKCOMPAT
#include <sys/stat.h>
#ifndef __NO_STAT64

extern int __dietlibc_lstat64(const char *__file, struct stat64 *__buf);
extern void __stat64_cvt(const struct stat *src,struct stat64 *dest);

int lstat64(const char *__file, struct stat64 *__buf) {
  if (__dietlibc_lstat64(__file,__buf)) {
    struct stat temp;
    if (errno!=ENOSYS) return -1;
    if (lstat(__file,&temp)) return -1;
    __stat64_cvt(&temp,__buf);
  }
  return 0;
}
#endif
#endif
