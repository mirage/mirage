#include <stdarg.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include "dietwarning.h"

int asprintf(char **s, const char *format,...)
{
  int n;
  va_list arg_ptr;
  va_start(arg_ptr, format);
  n=vsnprintf(0,1000000,format,arg_ptr);
  va_start (arg_ptr, format);
  if ((*s=malloc(n+1))) {
    n=vsnprintf(*s,n+1,format,arg_ptr);
    return n;
  }
  return -1;
}
