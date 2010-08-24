#define _GNU_SOURCE
#include <err.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

void vwarn(const char* f, va_list a) {
  vfdprintf(2,f,a);
  fdprintf(2,": %s\n",strerror(errno));
}
