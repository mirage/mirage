#define _GNU_SOURCE
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#undef __deprecated__
#define __deprecated__
#include <err.h>

void verr(int e,const char* f,va_list ap) {
  vwarn(f,ap);
  exit(e);
}
