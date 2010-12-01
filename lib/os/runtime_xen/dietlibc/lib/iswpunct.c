#include <wctype.h>

int __iswpunct_ascii(wint_t c);
int __iswpunct_ascii(wint_t c)
{
  return iswprint (c) && !iswalnum(c) && !iswspace(c);
}

int iswpunct(wint_t c) __attribute__((weak,alias("__iswpunct_ascii")));
