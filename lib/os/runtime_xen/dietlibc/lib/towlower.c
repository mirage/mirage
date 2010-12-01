#include <wctype.h>

wint_t towlower(wint_t c) {
  if ( (unsigned int)(c - 'A') < 26u )
    c += 'a' - 'A';
  return c;
}

