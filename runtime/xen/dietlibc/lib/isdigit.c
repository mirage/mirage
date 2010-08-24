#include <ctype.h>

int __isdigit_ascii ( int ch );
int __isdigit_ascii ( int ch ) {
    return (unsigned int)(ch - '0') < 10u;
}

int isdigit ( int ch ) __attribute__((weak,alias("__isdigit_ascii")));
