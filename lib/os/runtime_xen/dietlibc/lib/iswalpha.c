#include <ctype.h>
#include <wctype.h>

int __iswalpha_ascii(wint_t c);
int __iswalpha_ascii(wint_t c) {
  return (((unsigned char)c == c)?isalpha(c):0);
}

int iswalpha(wint_t c) __attribute__((weak,alias("__iswalpha_ascii")));
