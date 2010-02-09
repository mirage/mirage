#include <dietstdio.h>
#include <unistd.h>
#include <sys/stat.h>

#ifndef __NO_STAT64
int fseeko64_unlocked(FILE *stream, off64_t offset, int whence) {
  fflush_unlocked(stream);
  stream->bm=0; stream->bs=0;
  stream->flags&=~(ERRORINDICATOR|EOFINDICATOR);
  stream->ungotten=0;
  return lseek64(stream->fd,offset,whence)!=-1?0:-1;
}

int fseeko64(FILE *stream, off64_t offset, int whence) __attribute__((weak,alias("fseeko64_unlocked")));
#endif
