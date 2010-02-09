#include <stdarg.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include "dietfeatures.h"

int execl( const char *path,...) {
  va_list ap,bak;
  int n,i;
  char **argv,*tmp;
  va_start(ap, path);
  va_copy(bak,ap);
  n=1;
  while ((tmp=va_arg(ap,char *)))
    ++n;
  va_end (ap);
  if ((argv=(char **)alloca(n*sizeof(char*)))) {
    for (i=0; i<n; ++i)
      argv[i]=va_arg(bak,char *);
    va_end (bak);
    return execve(path,argv,environ);
  }
  va_end (bak);
  errno=ENOMEM;
  return -1;
}
