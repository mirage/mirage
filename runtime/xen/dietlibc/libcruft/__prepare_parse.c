#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "parselib.h"

void __prepare_parse(const char* filename,struct state* s) {
  int fd;
  s->cur=0;
  if (s->buffirst) return;	/* already mapped */
  fd=open(filename,O_RDONLY);
  if (fd>=0) {
    s->buflen=lseek(fd,0,SEEK_END);
    s->buffirst=mmap(0,s->buflen,PROT_READ,MAP_PRIVATE,fd,0);
    if (s->buffirst==(const char*)-1)
      s->buffirst=0;
    close(fd);
  } else {
    s->buflen=0;
    s->buffirst=0;
  }
}
