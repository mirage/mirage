#include <stdarg.h>
#include <sys/types.h>
#include <stdlib.h>
#include "dietstdio.h"
#include <unistd.h>

int scanf(const char *format, ...) {
  int n;
  va_list arg_ptr;
  va_start(arg_ptr, format);
  n=vfscanf(stdin,format,arg_ptr);
  va_end (arg_ptr);
  return n;
}
