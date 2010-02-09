#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>
#ifdef WANT_THREAD_SAFE
#include <pthread.h>
#endif
#include "dietstdio.h"

int __stdio_parse_mode(const char *mode) {
  int f=0;
  for (;;) {
    switch (*mode) {
    case 0: return f;
    case 'b': break;
    case 'r': f=O_RDONLY; break;
    case 'w': f=O_WRONLY|O_CREAT|O_TRUNC; break;
    case 'a': f=O_WRONLY|O_CREAT|O_APPEND; break;
    case '+': f=(f&(~O_WRONLY))|O_RDWR; break;
    }
    ++mode;
  }
}

