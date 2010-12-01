#include <stdarg.h>
#include <sys/types.h>
#include <stdio.h>

int snprintf(char *str,size_t size,const char *format,...)
{
  int n;
  va_list arg_ptr;
  va_start(arg_ptr, format);
  n=vsnprintf(str,size,format,arg_ptr);
  va_end (arg_ptr);
  return n;
}
