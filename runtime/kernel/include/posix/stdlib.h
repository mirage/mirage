#ifndef _POSIX_STDLIB_H
#define _POSIX_STDLIB_H

#include_next <stdlib.h>

#define realpath(p,r) strcpy(r,p)

#endif /* _POSIX_STDLIB_H */
