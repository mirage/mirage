#include <stdarg.h>
#include <sys/types.h>
#include <stdlib.h>
#include "dietstdio.h"
#include <unistd.h>

int vscanf(const char *format, va_list arg_ptr)
{
  return vfscanf(stdin,format,arg_ptr);
}
