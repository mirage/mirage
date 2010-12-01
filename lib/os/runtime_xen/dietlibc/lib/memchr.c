#include <string.h>
#include "dietfeatures.h"
#include "dietstring.h"

void* memchr(const void *s, int c, size_t n) {
  const unsigned char *pc = (unsigned char *) s;
  for (;n--;pc++)
    if (*pc == c)
      return ((void *) pc);
  return 0;
}
