#include <sys/types.h>
#include "parselib.h"

static int __isnonblank(int ch) {
  return (ch!=' ' && ch!='\t' && ch!='#');
}

size_t __parse_nws(struct state* s) {
  return __parse(s,__isnonblank);
}
