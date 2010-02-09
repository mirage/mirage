#include <unistd.h>
#include <stdlib.h>
#include "dietwarning.h"
#include "dietstdio.h"

FILE *__stdio_root;

int __stdio_atexit=0;

int fflush(FILE *stream) __attribute__((weak,alias("fflush_unlocked")));

void __stdio_flushall(void) {
  fflush(0);
}

int fflush_unlocked(FILE *stream) {
  if (stream==0) {
    int res;
    FILE *f;
    __fflush_stdin();
    __fflush_stdout();
    __fflush_stderr();
    for (res=0, f=__stdio_root; f; f=f->next)
      if (fflush(f))
	res=-1;
    return res;
  }
//  if (stream->flags&NOBUF) return 0;
  if (stream->flags&BUFINPUT) {
    register int tmp;
    if ((tmp=stream->bm-stream->bs)) {
      lseek(stream->fd,tmp,SEEK_CUR);
    }
    stream->bs=stream->bm=0;
  } else {
    if (stream->bm && write(stream->fd,stream->buf,stream->bm)!=(ssize_t)stream->bm) {
      stream->flags|=ERRORINDICATOR;
      return -1;
    }
    stream->bm=0;
  }
  return 0;
}

int __fflush4(FILE *stream,int next) {
  if (__unlikely(!__stdio_atexit)) {
    __stdio_atexit=1;
    atexit(__stdio_flushall);
  }
  if (__unlikely((stream->flags&BUFINPUT)!=next)) {
    int res=fflush_unlocked(stream);
    stream->flags=(stream->flags&~BUFINPUT)|next;
    return res;
  }
  if (stream->fd==0 && __stdin_is_tty()) __fflush_stdout();
  return 0;
}

/* Internal function, has no prototype.
 * This is defined here because of the weak symbol ELF semantics */
int __stdio_outs(const char *s,size_t len);
int __stdio_outs(const char *s,size_t len) {
  return fwrite(s,1,(size_t)len,stdout)==len?1:0;
}

link_warning("fflush","warning: your code uses stdio (7+k bloat).")
