#include <stdarg.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include "dietstdio.h"

static int __fwrite(void*ptr, size_t nmemb, int fd) {
  return write(fd,ptr,nmemb);
}

int vfdprintf(int fd, const char *format, va_list arg_ptr)
{
  struct arg_printf ap = { (void*)(long)fd, (int(*)(void*,size_t,void*)) __fwrite };
  return __v_printf(&ap,format,arg_ptr);
}
