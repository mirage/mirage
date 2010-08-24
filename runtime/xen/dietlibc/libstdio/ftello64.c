#include <dietstdio.h>
#include <unistd.h>
#include <sys/stat.h>

#ifndef __NO_STAT64
off64_t ftello64_unlocked(FILE *stream) {
  off64_t l;
  if (fflush_unlocked(stream)) return -1;
  return ((l=lseek64(stream->fd,0ull,SEEK_CUR))==-1?-1:l-stream->ungotten);
}

off64_t ftello64(FILE *stream) __attribute__((weak,alias("ftello64_unlocked")));
#endif
