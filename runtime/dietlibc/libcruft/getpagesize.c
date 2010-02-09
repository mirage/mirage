#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
/* for environ: */
#include <stdlib.h>

#ifndef PAGE_SIZE
#define PAGE_SIZE 4096
#endif

size_t __libc_getpagesize(void);
size_t __libc_getpagesize(void) {
  long* x=(long*)environ;
  int fd;
  while (*x) ++x; ++x;	/* skip envp to get to auxvec */
  while (*x) {
    if (*x==6)
      return x[1];
    x+=2;
  }
  return PAGE_SIZE;
}

size_t getpagesize(void)       __attribute__((weak,alias("__libc_getpagesize")));

