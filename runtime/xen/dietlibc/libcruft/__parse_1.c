#include <sys/types.h>
#include "parselib.h"

size_t __parse_1(struct state* s,char c) {
  size_t n;
  for (n=s->cur; n<s->buflen && s->buffirst[n]!='\n' && s->buffirst[n]!=c; ++n) ;
  return n-s->cur;
}

