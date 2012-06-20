#include <wctype.h>

int __iswupper_ascii ( wint_t c );
int __iswupper_ascii ( wint_t c )
{
    return (unsigned int)(c - 'A') < 26u;
}

int iswupper ( wint_t c ) __attribute__((weak,alias("__iswupper_ascii")));
