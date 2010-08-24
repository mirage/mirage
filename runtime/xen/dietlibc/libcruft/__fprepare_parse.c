#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "parselib.h"

void __fprepare_parse(int fd,struct state* s) {
  s->cur=0;
  if (s->buffirst) return;	/* already mapped */
  if (fd>=0) {
    s->buflen=lseek(fd,0,SEEK_END);
    s->buffirst=mmap(0,s->buflen,PROT_READ,MAP_PRIVATE,fd,0);
    if (s->buffirst==(const char*)-1)
      s->buffirst=0;
  }
}
