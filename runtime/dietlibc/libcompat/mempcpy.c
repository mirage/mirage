#define _GNU_SOURCE
#include <string.h>

void *mempcpy(void* __restrict__ _dst, const void* __restrict__ _src, size_t n) {
  char* dst=_dst;
  const char* src=_src;
  size_t i;
  for (i=0; i<n; ++i)
    dst[i]=src[i];
  return dst+i;
}
