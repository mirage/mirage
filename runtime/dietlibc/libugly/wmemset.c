#include <wchar.h>

wchar_t *wmemset(wchar_t *wcs, wchar_t wc, size_t n) {
  size_t i;
  for (i=0; i<n; ++i) wcs[i]=wc;
  return wcs;
}
