#include <wctype.h>

int iswdigit(wint_t c) {
    return (unsigned int)(c - '0') < 10u;
}
