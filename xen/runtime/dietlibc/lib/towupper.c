#include <wctype.h>

wint_t towupper(wint_t c) {
  if ( (unsigned int)(c - 'a') < 26u )
    c += 'A' - 'a';
  return c;
}

