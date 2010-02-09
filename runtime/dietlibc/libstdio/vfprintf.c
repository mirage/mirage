#include <stdarg.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include "dietstdio.h"

static int __fwrite(void*ptr, size_t nmemb, FILE* f) {
  return fwrite(ptr,1,nmemb,f);
}

int vfprintf(FILE *stream, const char *format, va_list arg_ptr)
{
  struct arg_printf ap = { stream, (int(*)(void*,size_t,void*)) __fwrite };
  return __v_printf(&ap,format,arg_ptr);
}
