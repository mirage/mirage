#include <ctype.h>
#include <wctype.h>

int __iswalnum_ascii(wint_t c);
int __iswalnum_ascii(wint_t c) {
  return (((unsigned char)c == c)?isalnum(c):0);
}

int iswalnum(wint_t c) __attribute__((weak,alias("__iswalnum_ascii")));
