#include <wchar.h>

int mbsinit(const mbstate_t* s) {
  return (!s || s->sofar);
}
