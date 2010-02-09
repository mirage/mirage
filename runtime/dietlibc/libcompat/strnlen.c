#define _GNU_SOURCE
#include <string.h>

size_t strnlen(const char *s,size_t maxlen) {
  const char* max=s+maxlen;
  const char* orig=s;
  while (s<max && *s) ++s;
  return s-orig;
}
