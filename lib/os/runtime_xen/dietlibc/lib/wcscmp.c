#include <wchar.h>

int wcscmp(const wchar_t* a,const wchar_t* b) {
  while (*a && *a == *b)
    a++, b++;
  return (*a - *b);
}

int wcscoll(const wchar_t *s,const wchar_t* t)       __attribute__((weak,alias("wcscmp")));
