#define _GNU_SOURCE
#include <stdarg.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include "dietwarning.h"

int vasprintf(char **s, const char *format, va_list ap)
{
  int n;
  va_list arg_ptr;
  va_copy(arg_ptr,ap);
  n=vsnprintf(0,1000000,format,arg_ptr);
  va_end(arg_ptr);
  if ((*s=malloc(n+1))) {
    n=vsnprintf(*s,n+1,format,ap);
    return n;
  }
  return -1;
}
