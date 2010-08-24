#include <string.h>

char* stpncpy (char *dst, const char *src, size_t n) {
  size_t i,j;
  for (i=0; i<n; ++i)
    if (!(dst[i]=src[i]))
      break;
  j=i;
  for (; i<n; ++i)
    dst[i]=0;

  return dst+j;
}
