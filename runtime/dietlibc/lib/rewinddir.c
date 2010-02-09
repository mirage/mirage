#include "dietdirent.h"
#include <unistd.h>
#include <dirent.h>

void rewinddir(DIR *d) {
  if (lseek(d->fd,0,SEEK_SET) != (off_t)-1)
    d->num=d->cur=0;
}
