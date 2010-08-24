#include <wctype.h>

int __iswblank_ascii(wint_t c);
int __iswblank_ascii(wint_t c) {
  return (c == ' ' || c == '\t');
}

int iswblank(wint_t c) __attribute__((weak,alias("__iswblank_ascii")));
