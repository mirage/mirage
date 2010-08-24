#include <ctype.h>
#include <sys/types.h>
#include "parselib.h"

size_t __parse(struct state* s,int (*pred)(int ch)) {
  size_t n;
  for (n=s->cur; n<s->buflen && s->buffirst[n]!='\n' && pred(s->buffirst[n]); ++n) ;
  return n-s->cur;
}

