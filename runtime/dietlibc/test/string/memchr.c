#include <string.h>
#include <assert.h>

int main() {
  const char* test="blubber";
  assert(memchr("aaaa",'x',4)==0);
  assert(memchr(0,'x',0)==0);
  assert(memchr(test,'u',7) == test+2);
  assert(memchr(test,'b',7)==test);
  assert(memchr(test+6,'r',1)==test+6);
  return 0;
}
