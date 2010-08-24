#include "dietstdio.h"
#include <stdlib.h>
#include <unistd.h>

int fclose_unlocked(FILE *stream) {
  int res;
  FILE *f,*fl;
  res=fflush_unlocked(stream);
  res|=__libc_close(stream->fd);
  for (fl=0,f=__stdio_root; f; fl=f,f=f->next)
    if (f==stream) {
      if (fl)
	fl->next=f->next;
      else
	__stdio_root=f->next;
      break;
    }
  if ((!(stream->flags&STATICBUF))&&(stream->buf))
    free(stream->buf);
  free(stream);
  return res;
}

int fclose(FILE *stream) __attribute__((weak,alias("fclose_unlocked")));
