#include <stdlib.h>
#include <string.h>
#include <assert.h>

int main() {
  assert(getenv("PATH"));
  putenv("foo=bar");
  assert(!strcmp(getenv("foo"),"bar"));
  return 0;
}
