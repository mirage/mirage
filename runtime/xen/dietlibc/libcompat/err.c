#define _GNU_SOURCE
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#undef __deprecated__
#define __deprecated__
#include <err.h>

void err(int e,const char* f, ...) {
  va_list ap;
  va_start(ap,f);
  vwarn(f,ap);
  va_end(ap);
  exit(e);
}
