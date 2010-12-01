#include <stdio.h>

int fgetpos(FILE *stream, fpos_t *pos) {
  long l=ftell(stream);
  if (l==-1) return -1;
  *pos=l;
  return 0;
}
