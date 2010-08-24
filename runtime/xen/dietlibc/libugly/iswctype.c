#include <wctype.h>
#include <string.h>

int iswctype(wint_t wc, wctype_t desc) {
  return desc(wc);
}
