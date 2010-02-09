#include <stdarg.h>
#include <sys/types.h>
#include <stdlib.h>
#include "dietstdio.h"
#include <unistd.h>

struct str_data {
  unsigned char* str;
};

static int sgetc(struct str_data* sd) {
  register unsigned int ret = *(sd->str++);
  return (ret)?(int)ret:-1;
}

static int sputc(int c, struct str_data* sd) {
  return (*(--sd->str)==c)?c:-1;
}

int vsscanf(const char* str, const char* format, va_list arg_ptr)
{
  struct str_data  fdat = { (unsigned char*)str };
  struct arg_scanf farg = { (void*)&fdat, (int(*)(void*))sgetc, (int(*)(int,void*))sputc };
  return __v_scanf(&farg,format,arg_ptr);
}
