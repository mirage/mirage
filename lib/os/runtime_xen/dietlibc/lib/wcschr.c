#include <wchar.h>

wchar_t* wcschr(const wchar_t *wcs, wchar_t wc) {
  for (; *wcs; ++wcs)
    if (*wcs == wc)
      return (wchar_t*)wcs;
  return 0;
}
