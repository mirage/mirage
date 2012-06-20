#include <wctype.h>

int __iswspace_ascii(wint_t c);
int __iswspace_ascii(wint_t c) {
  return (unsigned int)(c - 9) < 5u  ||  c == ' ';
}

int iswspace(wint_t c) __attribute__((weak,alias("__iswspace_ascii")));
