#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include "dietstdio.h"
#include <stdlib.h>
#ifdef WANT_THREAD_SAFE
#include <pthread.h>
#endif

extern int __stdio_atexit;

FILE*__stdio_init_file(int fd,int closeonerror,int mode) {
  FILE *tmp=(FILE*)malloc(sizeof(FILE));
  if (!tmp) goto err_out;
  tmp->buf=(char*)malloc(BUFSIZE);
  if (!tmp->buf) {
    free(tmp);
err_out:
    if (closeonerror) __libc_close(fd);
    errno=ENOMEM;
    return 0;
  }
  tmp->fd=fd;
  tmp->bm=0;
  tmp->bs=0;
  tmp->buflen=BUFSIZE;
  {
    struct stat st;
    fstat(fd,&st);
    tmp->flags=(S_ISFIFO(st.st_mode))?FDPIPE:0;
  }
  switch (mode&3) {
  case O_RDWR: tmp->flags|=CANWRITE;
  case O_RDONLY: tmp->flags|=CANREAD; break;
  case O_WRONLY: tmp->flags|=CANWRITE;
  }
  tmp->popen_kludge=0;
  if (__stdio_atexit==0) {
    __stdio_atexit=1;
    atexit(__stdio_flushall);
  }
  tmp->next=__stdio_root;
  __stdio_root=tmp;
  tmp->ungotten=0;
  return tmp;
}

FILE* __stdio_init_file_nothreads(int fd,int closeonerror,int mode) __attribute__((alias("__stdio_init_file")));
