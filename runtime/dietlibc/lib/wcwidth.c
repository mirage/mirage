#define _XOPEN_SOURCE
#include <wchar.h>

int wcwidth(wchar_t c) {
  if (!c) return 0;
  if (c<' ') return -1;
  return 1;
}
