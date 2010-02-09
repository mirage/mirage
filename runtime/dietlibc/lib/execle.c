#include <stdarg.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include "dietfeatures.h"

int execle( const char *path,...) {
  va_list ap;
  int n,i;
  char **argv,*tmp, **env;
  va_start(ap, path);
  n=1;
  while ((tmp=va_arg(ap,char *)))
    ++n;
  va_end (ap);
  if ((argv=(char **)alloca(n*sizeof(char*)))) {
    va_start(ap, path);
    for (i=0; i<n; ++i)
      argv[i]=va_arg(ap,char *);
    env=va_arg(ap, char **);
    va_end (ap);
    return execve(path,argv,env);
  }
  errno=ENOMEM;
  return -1;
}
