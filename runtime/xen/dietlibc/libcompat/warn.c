#define _GNU_SOURCE
#include <err.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

void warn(const char* f, ...) {
  va_list ap;
  va_start(ap,f);
  vfdprintf(2,f,ap);
  fdprintf(2,": %s\n",strerror(errno));
  va_end(ap);
}
