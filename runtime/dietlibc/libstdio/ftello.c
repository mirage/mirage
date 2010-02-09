#include <dietstdio.h>
#include <unistd.h>

off_t ftello_unlocked(FILE *stream) {
  off_t l;
  if (fflush_unlocked(stream)) return -1;
  return ((l=lseek(stream->fd,0,SEEK_CUR))==-1?-1:l-stream->ungotten);
}

off_t ftello(FILE *stream) __attribute__((weak,alias("ftello_unlocked")));
