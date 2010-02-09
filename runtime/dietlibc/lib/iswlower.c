#include <wctype.h>

int __iswlower_ascii(wint_t c);
int __iswlower_ascii(wint_t c) {
  return (unsigned int) (c - 'a') < 26u;
}

int iswlower ( wint_t ch ) __attribute__((weak,alias("__iswlower_ascii")));
