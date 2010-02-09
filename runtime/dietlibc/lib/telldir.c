#include "dietdirent.h"
#include <unistd.h>
#include <dirent.h>

off_t telldir(DIR *d) {
  off_t result = 0;
  if (lseek(d->fd,0,SEEK_CUR))
    result=((struct dirent*)(d->buf+d->cur))->d_off;
  return result;
}
