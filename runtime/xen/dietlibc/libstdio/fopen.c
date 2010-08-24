#include <sys/types.h>
#include <dietstdio.h>
#include <unistd.h>

extern int __stdio_atexit;

/* this is needed so the libpthread wrapper can initialize the mutex,
 * not to lock it */

FILE *fopen_unlocked(const char *path, const char *mode) {
  int f=0;	/* O_RDONLY, O_WRONLY or O_RDWR */
  int fd;

  f=__stdio_parse_mode(mode);
  if ((fd=__libc_open(path,f,0666))<0)
    return 0;
  return __stdio_init_file(fd,1,f);
}

FILE *fopen(const char *path, const char *mode) __attribute__((weak,alias("fopen_unlocked")));
