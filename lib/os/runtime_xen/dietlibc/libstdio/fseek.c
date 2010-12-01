#include <dietstdio.h>
#include <unistd.h>

int fseek_unlocked(FILE *stream, long offset, int whence) {
  fflush_unlocked(stream);
  stream->bm=0; stream->bs=0;
  stream->flags&=~(ERRORINDICATOR|EOFINDICATOR);
  stream->ungotten=0;
  return lseek(stream->fd,offset,whence)!=-1?0:-1;
}

int fseek(FILE *stream, long offset, int whence) __attribute__((weak,alias("fseek_unlocked")));
