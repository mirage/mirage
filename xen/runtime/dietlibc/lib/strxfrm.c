#include <sys/types.h>
#include <string.h>
#include "dietfeatures.h"

size_t strxfrm(char *dest, const char *src, size_t n) {
#ifdef WANT_FULL_POSIX_COMPAT
  memset(dest,0,n);
#endif
  memccpy(dest,src,0,n);
  return strlen(dest);
}

