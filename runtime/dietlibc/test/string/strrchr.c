#include <assert.h>
#include <string.h>

int main() {
  const char* x="foo bar baz";
  assert(strrchr(x,'z')==x+10);
  assert(strrchr(x,' ')==x+7);
  assert(strrchr(x,'x')==0);
  return 0;
}
