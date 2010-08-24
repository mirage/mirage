#include <wctype.h>

int __iswcntrl_ascii(wint_t c);
int __iswcntrl_ascii(wint_t c) {
  return ((unsigned int)c < 32u || c == 127);
}

int iswcntrl(wint_t c) __attribute__((weak,alias("__iswcntrl_ascii")));
