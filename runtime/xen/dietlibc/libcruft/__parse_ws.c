#include <sys/types.h>
#include <ctype.h>
#include "parselib.h"

static int __isblank(int ch) {
  return (ch==' ' || ch=='\t');
}

size_t __parse_ws(struct state* s) {
  return __parse(s,__isblank);
}
