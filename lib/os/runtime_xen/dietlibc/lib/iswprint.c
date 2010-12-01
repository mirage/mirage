#include <wctype.h>

int __iswprint_ascii(wint_t c);
int __iswprint_ascii(wint_t c) {
    return (unsigned int)(c - ' ') < 127u - ' ';
}

int iswprint(wint_t c) __attribute__((weak,alias("__iswprint_ascii")));
