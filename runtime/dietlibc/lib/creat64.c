#include <fcntl.h>

#ifndef O_LARGEFILE
#define O_LARGEFILE 0
#endif

int creat64(const char *file,mode_t mode) {
  return open(file,O_WRONLY|O_CREAT|O_TRUNC|O_LARGEFILE,mode);
}
