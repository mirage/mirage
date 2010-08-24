#define _GNU_SOURCE
#include <strings.h>
#include <string.h>
#include <assert.h>

int main() {
  assert(ffs(1)==1);
  assert(ffs(2)==2);
  assert(ffs(4)==3);
  assert(ffs(256)==9);
  assert(ffs(511)==1);
  assert(ffsll(511)==1);
  assert(ffsll(256)==9);
  assert(ffsll(0x200000000ll)==34);

  return 0;
}
