#include <stdio.h>
#include <string.h>
#include <assert.h>

int main() {
  assert(strspn("foo:bar:",":=b")==0);
  assert(strspn("foo:bar:",":=of")==4);
  return 0;
}
