#include <errno.h>
#include "dietfeatures.h"
#ifdef WANT_LARGEFILE_BACKCOMPAT
#include <sys/sendfile.h>
#ifndef __NO_STAT64

extern ssize_t __dietlibc_sendfile64 (int out_fd, int in_fd, loff_t* offset,
			   size_t count);

ssize_t sendfile64 (int out_fd, int in_fd, loff_t* offset, size_t count) {
  static int havesendfile64=1;
  ssize_t r = -1;
  if (havesendfile64) {
    r=__dietlibc_sendfile64(out_fd,in_fd,offset,count);
    if (r==-1 && errno==ENOSYS)
      havesendfile64=0;
  }
  if (!havesendfile64) {
    off_t o=*offset;
    if (*offset>0x7fffffff) { errno=EINVAL; return -1; }
    r=sendfile(out_fd,in_fd,&o,count);
    *offset=o;
    return r;
  }
  return r;
}
#endif
#endif
