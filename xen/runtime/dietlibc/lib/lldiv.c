#define _GNU_SOURCE
#include <stdlib.h>

lldiv_t lldiv(long long numerator, long long denominator) {
  lldiv_t x;
  x.quot=numerator/denominator;
  x.rem=numerator-x.quot*denominator;
  return x;
}
