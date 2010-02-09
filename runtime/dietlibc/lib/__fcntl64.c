#include <errno.h>
#include "dietfeatures.h"
#ifdef WANT_LARGEFILE_BACKCOMPAT
#include <sys/stat.h>
#ifndef __NO_STAT64
#include <fcntl.h>
#include <stdarg.h>

extern int __dietlibc_fcntl64(int __fd, int cmd, ...);

int fcntl64(int fd, int cmd, ...) {
  va_list va;
  va_start(va,cmd);
  switch (cmd) {
  case F_GETLK:
  case F_SETLK:
  case F_SETLKW:
    {
      struct flock64* x = va_arg(va,struct flock64*);
      struct flock tmp;
      int res;
      if ((res=__dietlibc_fcntl64(fd,cmd,x))) {
	if (errno!=ENOSYS) return -1;
	tmp.l_type=x->l_type;
	tmp.l_whence=x->l_whence;
	tmp.l_start=x->l_start;
	tmp.l_len=x->l_len;
	tmp.l_pid=x->l_pid;
	if (tmp.l_len != x->l_len || tmp.l_start != x->l_start) {
	  errno=EOVERFLOW;
	  return -1;
	}
	res=fcntl(fd,cmd,&tmp);
	if (cmd==F_GETLK) {
	  x->l_type=tmp.l_type;
	  x->l_whence=tmp.l_whence;
	  x->l_start=tmp.l_start;
	  x->l_len=tmp.l_len;
	  x->l_pid=tmp.l_pid;
	}
      }
      return res;
    }

  default:
    {
      long arg = va_arg(va,long);
      int res;
      if ((res=__dietlibc_fcntl64(fd,cmd,arg))==-1) {
	if (errno!=ENOSYS) return -1;
	return fcntl(fd,cmd,arg);
      }
      return res;
    }
  }
}
#endif
#endif
