#include <wchar.h>

wchar_t *wmemcpy(wchar_t *dest, const wchar_t *src, size_t n) {
  size_t i;
  for (i=0; i<n; ++i)
    dest[i]=src[i];
  return dest;
}
