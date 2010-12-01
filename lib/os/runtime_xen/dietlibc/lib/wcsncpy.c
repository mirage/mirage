#include <wchar.h>

wchar_t* wcsncpy(wchar_t *__restrict__ dest, const wchar_t *__restrict__ src,size_t n) {
  wchar_t* orig=dest;
  for (; dest<orig+n && (*dest=*src); ++src,++dest) ;
  for (; dest<orig+n; ++dest) *dest=0;
  return orig;
}
