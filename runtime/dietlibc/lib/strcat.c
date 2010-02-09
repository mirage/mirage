#include "dietfeatures.h"
#include <string.h>

char* strcat(register char* s,register const char* t)
{
  char *dest=s;
  s+=strlen(s);
  for (;;) {
    if (!(*s = *t)) break; ++s; ++t;
#ifndef WANT_SMALL_STRING_ROUTINES
    if (!(*s = *t)) break; ++s; ++t;
    if (!(*s = *t)) break; ++s; ++t;
    if (!(*s = *t)) break; ++s; ++t;
#endif
  }
  return dest;
}

