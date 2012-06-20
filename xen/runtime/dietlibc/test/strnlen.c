#define _GNU_SOURCE
#include <string.h>
#include <assert.h>

int main() {
  assert(strnlen("fnord",3)==3);
  assert(strnlen("fnord",17)==5);
}
