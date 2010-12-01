#include <wctype.h>

int __iswxdigit_ascii(wint_t c);
int __iswxdigit_ascii(wint_t c)
{
    return (unsigned int)( c         - '0') < 10u  ||
           (unsigned int)((c | 0x20) - 'a') <  6u;
}

int iswxdigit(wint_t c) __attribute__((weak,alias("__iswxdigit_ascii")));
