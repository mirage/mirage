#define _GNU_SOURCE
#include <err.h>
#include <stdio.h>

void vwarnx(const char* f, va_list a) {
  vfdprintf(2,f,a);
}
