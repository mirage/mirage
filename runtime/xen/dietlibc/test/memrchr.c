#define _GNU_SOURCE
#include <string.h>
#include <assert.h>

int main() {
  const char* test="blubber";
  assert(memrchr("aaaa",'x',4)==0);
  assert(memrchr(0,'x',0)==0);
  assert(memrchr(test,'u',7) == test+2);
  assert(memrchr(test,'b',7)==test+4);
  assert(memrchr(test+6,'r',1)==test+6);
  return 0;
}
