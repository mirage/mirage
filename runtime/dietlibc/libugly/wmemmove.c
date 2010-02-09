#include <wchar.h>

wchar_t *wmemmove(wchar_t *dest, const wchar_t *src, size_t n) {
  size_t i;
  if (src<dest && dest<src+n)
    for (i=0; i<n; ++i)
      dest[n-i-1]=src[n-i-1];
  else
    for (i=0; i<n; ++i)
      dest[i]=src[i];
  return dest;
}
