#include <wchar.h>

wchar_t* wcscpy(wchar_t *__restrict__ dest, const wchar_t *__restrict__ src) {
  wchar_t* orig=dest;
  for (; (*dest=*src); ++src,++dest) ;
  return orig;
}
