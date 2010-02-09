#include <stdarg.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include "dietstdio.h"

int printf(const char *format,...)
{
  int n;
  va_list arg_ptr;
  va_start(arg_ptr, format);
  n=vprintf(format, arg_ptr);
  va_end(arg_ptr);
  return n;
}
