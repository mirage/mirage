#include <wchar.h>
#include <wctype.h>
#include <assert.h>

int main() {
  wctype_t x;
  assert(x=wctype("lower"));
  assert(iswctype(L'o',x));
}
