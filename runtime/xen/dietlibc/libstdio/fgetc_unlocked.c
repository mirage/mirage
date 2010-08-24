#include "dietstdio.h"
#include <unistd.h>

int fgetc_unlocked(FILE *stream) {
  unsigned char c;
  if (__unlikely(!(stream->flags&CANREAD))) goto kaputt;
  if (__unlikely(stream->ungotten)) {
    stream->ungotten=0;
    return stream->ungetbuf;
  }

  /* common case first */
  if (__likely(stream->bm<stream->bs))
    return (unsigned char)stream->buf[stream->bm++];

  if (__unlikely(feof_unlocked(stream)))
    return EOF;
  if (__fflush4(stream,BUFINPUT)) return EOF;
  if (__unlikely(stream->bm>=stream->bs)) {
    ssize_t len=__libc_read(stream->fd,stream->buf,stream->buflen);
    if (len==0) {
      stream->flags|=EOFINDICATOR;
      return EOF;
    } else if (len<0) {
kaputt:
      stream->flags|=ERRORINDICATOR;
      return EOF;
    }
    stream->bm=0;
    stream->bs=len;
  }
  c=stream->buf[stream->bm];
  ++stream->bm;
  return c;
}

int fgetc(FILE* stream) __attribute__((weak,alias("fgetc_unlocked")));
