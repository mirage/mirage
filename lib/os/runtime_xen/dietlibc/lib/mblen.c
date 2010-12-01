#include <stdlib.h>
#include <wchar.h>

int mblen(const char* s,size_t n) {
  return mbrlen(s,n,NULL);
}
