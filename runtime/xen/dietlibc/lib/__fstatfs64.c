#include <errno.h>
#include "dietfeatures.h"
#include <sys/statfs.h>

#if __WORDSIZE == 32

extern int __dietlibc_fstatfs64(int fd, size_t bufsize, struct statfs64 *__buf);
extern void __statfs64_cvt(const struct statfs *src,struct statfs64 *dest);

int fstatfs64(int fd, struct statfs64 *__buf) {
#ifdef WANT_LARGEFILE_BACKCOMPAT
  if (__dietlibc_fstatfs64(fd,sizeof(*__buf),__buf)) {
    struct statfs temp;
    if (errno!=ENOSYS) return -1;
    if (fstatfs(fd,&temp)) return -1;
    __statfs64_cvt(&temp,__buf);
  }
  return 0;
#else
  return __dietlibc_fstatfs64(fd,sizeof(*__buf),__buf);
#endif
}
#endif
