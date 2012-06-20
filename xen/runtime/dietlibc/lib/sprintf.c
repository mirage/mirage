#include <stdarg.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>

int sprintf(char *dest,const char *format,...)
{
  int n;
  va_list arg_ptr;
  va_start(arg_ptr, format);
  n=vsprintf(dest,format,arg_ptr);
  va_end (arg_ptr);
  return n;
}
