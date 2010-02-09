#include "dietdirent.h"
#include <unistd.h>
#include <dirent.h>
#include <stdlib.h>

struct dirent* readdir(DIR *d) {
  if (!d->num || (d->cur += ((struct dirent*)(d->buf+d->cur))->d_reclen)>=d->num) {
    int res=getdents(d->fd,(struct dirent*)d->buf,sizeof (d->buf)-1);
    if (res<=0) return 0;
    d->num=res; d->cur=0;
  }
  return (struct dirent*)(d->buf+d->cur);
}
