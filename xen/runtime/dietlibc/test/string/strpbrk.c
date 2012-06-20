#include <stdio.h>
#include <string.h>
#include <assert.h>

int main() {
  const char* c;
  c="fnord:foo:bar:baz"; assert(strpbrk(c,":")==c+5);
  c=":/::/:foo/bar:baz"; assert(strpbrk(c,"/:")==c);
  return 0;
}
