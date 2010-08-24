#include <dietstdio.h>
#include <unistd.h>
#include <errno.h>

long ftell_unlocked(FILE *stream) {
  off_t l;
  if (stream->flags&3 || (l=lseek(stream->fd,0,SEEK_CUR))==-1) return -1;
  if (stream->flags&BUFINPUT)
    return l-(stream->bs-stream->bm)-stream->ungotten;
  else
    return l+stream->bm;
}

long ftell(FILE *stream) __attribute__((weak,alias("ftell_unlocked")));
