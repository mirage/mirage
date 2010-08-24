#define _POSIX_SOURCE
#define _XOPEN_SOURCE
#include <sys/types.h>
#include <string.h>
#include "dietfeatures.h"

/* gcc is broken and has a non-SUSv2 compliant internal prototype.
 * This causes it to warn about a type mismatch here.  Ignore it. */
char *strncpy(char *dest, const char *src, size_t n) {
#ifdef WANT_FULL_POSIX_COMPAT
  memset(dest,0,n);
#endif
  memccpy(dest,src,0,n);
#ifdef WANT_NON_COMPLIANT_STRNCAT
  if (n) dest[n-1]=0;	/* maybe we should rather abort() if n is 0? */
#endif
  return dest;
}
