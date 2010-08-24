#include <strings.h>

int  strcasecmp ( const char* s1, const char* s2 )
{
    register unsigned int  x2;
    register unsigned int  x1;

    while (1) {
        x2 = *s2 - 'A'; if (__unlikely(x2 < 26u)) x2 += 32;
        x1 = *s1 - 'A'; if (__unlikely(x1 < 26u)) x1 += 32;
	s1++; s2++;
        if ( __unlikely(x2 != x1) )
            break;
        if ( __unlikely(x1 == (unsigned int)-'A') )
            break;
    }

    return x1 - x2;
}
