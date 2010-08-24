#include <sys/types.h>
#include <fcntl.h>

#ifndef O_LARGEFILE
#define O_LARGEFILE 0
#endif

int __libc_open64(const char* file,int oflag,int mode);
int __libc_open64(const char* file,int oflag,int mode) {
  return open(file,oflag|O_LARGEFILE,mode);
}

int open64(const char* file,int oflag,...) __attribute__((weak,alias("__libc_open64")));
