#include <dietstdio.h>

int feof_unlocked(FILE*stream) {
  /* yuck!!! */
  if (stream->ungotten) return 0;
  return (stream->flags&EOFINDICATOR);
}
int feof(FILE*stream)
__attribute__((weak,alias("feof_unlocked")));
