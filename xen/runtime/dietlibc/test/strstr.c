#include <string.h>
#include <assert.h>

int main() {
  char buf[]="foo bar baz";
  assert(strstr(buf,"bar")==buf+4);
  assert(strstr(buf,"baz")==buf+8);
  assert(strstr(buf,"barney")==0);
  assert(strstr(buf,"foo")==buf);
  assert(strstr(buf,"")==buf);
  return 0;
}
