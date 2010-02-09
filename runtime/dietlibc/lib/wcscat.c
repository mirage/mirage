#include <wchar.h>

wchar_t* wcscat(wchar_t *__restrict__ dest, const wchar_t *__restrict__ src) {
  wchar_t* orig=dest;
  for (; *dest; ++dest) ;	/* go to end of dest */
  for (; (*dest=*src); ++src,++dest) ;	/* then append from src */
  return orig;
}
