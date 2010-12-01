#include "dietfeatures.h"
#include <string.h>

char *strchr(register const char *t, int c) {
  register char ch;

  ch = c;
  for (;;) {
    if (__unlikely(*t == ch)) break; if (__unlikely(!*t)) return 0; ++t;
#ifndef WANT_SMALL_STRING_ROUTINES
    if (__unlikely(*t == ch)) break; if (__unlikely(!*t)) return 0; ++t;
    if (__unlikely(*t == ch)) break; if (__unlikely(!*t)) return 0; ++t;
    if (__unlikely(*t == ch)) break; if (__unlikely(!*t)) return 0; ++t;
#endif
  }
  return (char*)t;
}

char *index(char *t,int c)	__attribute__((weak,alias("strchr")));
