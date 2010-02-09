#include <unistd.h>
#include <stdlib.h>
#include <errno.h>

extern int __syscall_getcwd(char* buf, size_t size);

char *getcwd(char *buf, size_t size) {
  if (__unlikely(!size)) {
    errno=EINVAL;
    buf=0;
  } else {
    int tmp;
    if ((tmp=__syscall_getcwd(buf,size-1))<0) return 0;
    buf[tmp]=0;
  }
  return buf;
}
