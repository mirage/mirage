#include <sys/types.h>
#include "dietstdio.h"
#include <unistd.h>

size_t fread_unlocked(void *ptr, size_t size, size_t nmemb, FILE *stream) {
  int res;
  unsigned long i,j;
  j=size*nmemb;
  i=0;

  if (!(stream->flags&CANREAD)) {
    stream->flags|=ERRORINDICATOR;
    return 0;
  }
  if (!j || j/nmemb!=size) return 0;
  if (stream->ungotten) {
    stream->ungotten=0;
    *(char*)ptr=stream->ungetbuf;
    ++i;
    if (j==1) return 1;
  }

#ifdef WANT_FREAD_OPTIMIZATION
  if ( !(stream->flags&FDPIPE) && (j>stream->buflen)) {
    size_t tmp=j-i;
    ssize_t res;
    size_t inbuf=stream->bs-stream->bm;
    memcpy(ptr+i,stream->buf+stream->bm,inbuf);
    stream->bm=stream->bs=0;
    tmp-=inbuf;
    i+=inbuf;
    if (fflush_unlocked(stream)) return 0;
    while ((res=__libc_read(stream->fd,ptr+i,tmp))<(ssize_t)tmp) {
      if (res==-1) {
	stream->flags|=ERRORINDICATOR;
	goto exit;
      } else if (!res) {
	stream->flags|=EOFINDICATOR;
	goto exit;
      }
      i+=res; tmp-=res;
    }
    return nmemb;
  }
#endif
  for (; i<j; ++i) {
    res=fgetc_unlocked(stream);
    if (res==EOF)
exit:
      return i/size;
    else
      ((unsigned char*)ptr)[i]=(unsigned char)res;
  }
  return nmemb;
}

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream) __attribute__((weak,alias("fread_unlocked")));
