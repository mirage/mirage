#include <wchar.h>

int wmemcmp(const wchar_t *s1, const wchar_t *s2, size_t n) {
  size_t i;
  for (i=0; i<n; ++i) {
    wint_t x=s1[i]-s2[i];
    if (x) return x;
  }
  return 0;
}
