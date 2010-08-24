#include <errno.h>
#include "dietfeatures.h"
#include <sys/types.h>
#include <dietstdio.h>
#include <unistd.h>

FILE *fdopen_unlocked(int filedes, const char *mode) {
  int f=0;	/* O_RDONLY, O_WRONLY or O_RDWR */

  f=__stdio_parse_mode(mode);
  if (filedes<0) { errno=EBADF; return 0; }
  return __stdio_init_file(filedes,0,f);
}

FILE *fdopen(int filedes, const char *mode) __attribute__((weak,alias("fdopen_unlocked")));
