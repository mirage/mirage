#include <stdlib.h>
#include <wchar.h>

int wctomb(char *pwc, wchar_t s) {
  return wcrtomb(pwc,s,NULL);
}
