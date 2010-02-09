#include "dietdirent.h"
#include <sys/mman.h>
#include <unistd.h>
#include <dirent.h>
#include <stdlib.h>

int closedir (DIR* d) {
  int res=close(d->fd);
  munmap (d, PAGE_SIZE);
  return res;
}
