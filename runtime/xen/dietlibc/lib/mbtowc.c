#include <stdlib.h>
#include <wchar.h>

int mbtowc(wchar_t *pwc, const char *s, size_t n) {
  return mbrtowc(pwc,s,n,NULL);
}
