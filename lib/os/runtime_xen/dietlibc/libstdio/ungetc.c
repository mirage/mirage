#include "dietstdio.h"

int ungetc_unlocked(int c, FILE *stream) {
  if (stream->ungotten || c<0 || c>255)
    return EOF;
  stream->ungotten=1;
  stream->ungetbuf=(unsigned char)c;
  stream->flags&=~(ERRORINDICATOR|EOFINDICATOR);
  return c;
}

int ungetc(int c, FILE *stream) __attribute__((weak,alias("ungetc_unlocked")));
