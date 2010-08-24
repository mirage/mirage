#include <stdlib.h>
#include <wchar.h>

size_t mbstowcs(wchar_t *dest, const char *src, size_t n) {
  const char** s=&src;
  return mbsrtowcs(dest,s,n,NULL);
}
