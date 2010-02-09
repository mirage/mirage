#define _GNU_SOURCE
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#undef __deprecated__
#define __deprecated__
#include <err.h>

void verrx(int e,const char* f,va_list ap) {
  vwarnx(f,ap);
  exit(e);
}
