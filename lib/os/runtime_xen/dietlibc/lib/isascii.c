#include <ctype.h>

int isascii ( int ch ) 
{
    return (unsigned int)ch < 128u;
}
