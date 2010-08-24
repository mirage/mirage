#include "dietstdio.h"
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

/* this is needed so the libpthread wrapper can initialize the mutex,
 * not to lock it */

FILE *tmpfile_unlocked(void) {
  int fd;
  char template[20] = "/tmp/tmpfile-XXXXXX";
  if ((fd=mkstemp(template))<0)
    return 0;
  unlink(template);
  return __stdio_init_file(fd,1,O_RDWR);
}

FILE *tmpfile(void) __attribute__((weak,alias("tmpfile_unlocked")));
