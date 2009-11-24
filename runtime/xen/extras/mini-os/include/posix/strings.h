#ifndef _POSIX_STRINGS_H
#define _POSIX_STRINGS_H

#include <string.h>

#define bzero(ptr, size) (memset((ptr), '\0', (size)), (void) 0)

int ffs (int i);
int ffsl (long int li);
int ffsll (long long int lli);

#endif /* _POSIX_STRINGS_H */
