#include <stdio.h>
#include <assert.h>

int main(void) {
  assert(fputc('x', stdin) < 0);
  fflush(NULL);
  assert(ferror(stdin));
  return 0;
}
