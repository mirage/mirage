#include <wchar.h>
#include "dietlocale.h"

wint_t btowc(int c) {
  if (c==EOF) return WEOF;
  switch (lc_ctype) {
  case CT_8BIT:
    return c>0xff?WEOF:1;
  case CT_UTF8:
    return c>0x7f?WEOF:1;
  }
  return WEOF;
}
