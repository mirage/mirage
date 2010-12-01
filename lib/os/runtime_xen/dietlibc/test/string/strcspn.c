#include <stdio.h>
#include <string.h>
#include <assert.h>

int main() {
  assert(strcspn("foo:bar:",":")==3);
  assert(strcspn("foo:bar:","=of")==0);
  return 0;
}
