#define _GNU_SOURCE
#include <err.h>
#include <stdio.h>

void warnx(const char* f, ...) {
  va_list ap;
  va_start(ap,f);
  vfdprintf(2,f,ap);
  va_end(ap);
}
