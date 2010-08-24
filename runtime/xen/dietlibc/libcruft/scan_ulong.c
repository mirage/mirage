#include <ctype.h>
#include <sys/types.h>
#include "parselib.h"

size_t scan_ulong(const char* s,unsigned long* l) {
  size_t n;
  unsigned long x;
  unsigned int digit;
  for (x=n=0; (digit=(s[n]-'0'))<10u; ++n)
    x=x*10+digit;
  *l=x;
  return n;
}
