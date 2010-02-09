#include <endian.h>
#include <stdlib.h>

#if __WORDSIZE != 64
long long int llabs(long long int i) { if (i<0) i=-i; return i; }
#endif
