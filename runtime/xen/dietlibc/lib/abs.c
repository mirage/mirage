#include <endian.h>
#include <stdlib.h>

int abs(int i) { return i>=0?i:-i; }
#if __WORDSIZE == 32
long labs(long i) __attribute__((alias("abs")));
#endif
