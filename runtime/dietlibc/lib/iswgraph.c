#include <wctype.h>

int __iswgraph_ascii(wint_t c);
int __iswgraph_ascii(wint_t c) {
  return (unsigned int)(c - '!') < 127u - '!';
}

int iswgraph(wint_t c) __attribute__((weak,alias("__iswgraph_ascii")));
