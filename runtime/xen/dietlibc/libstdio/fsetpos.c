#include <stdio.h>

int fsetpos(FILE *stream, fpos_t *pos) {
  if (fseek(stream,*pos,SEEK_SET)==-1)
    return -1;
  return 0;
}
