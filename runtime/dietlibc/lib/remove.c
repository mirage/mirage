#include <unistd.h>
#include <errno.h>
#include "dietfeatures.h"
#include <stdio.h>

int remove(const char* filename) {
  if (unlink(filename)) {
    if (errno==EISDIR)
      return rmdir(filename);
    return -1;
  }
  return 0;
}
