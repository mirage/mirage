#include <sys/types.h>
#include "dietdirent.h"
#define _BSD_SOURCE
#include <dirent.h>

int dirfd(DIR* dirp) {
  return dirp->fd;
}
