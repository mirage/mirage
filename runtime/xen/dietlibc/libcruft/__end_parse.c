#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "parselib.h"

void __end_parse(struct state* s) {
  munmap((void*)(s->buffirst),s->buflen);
  s->buffirst=0;
}
