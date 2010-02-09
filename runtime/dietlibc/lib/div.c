#include "dietwarning.h"
#include <stdlib.h>

div_t div(int numerator, int denominator) {
  div_t x;
  x.quot=numerator/denominator;
  x.rem=numerator-x.quot*denominator;
  return x;
}

link_warning("div","warning: your code uses div(), which is completely superfluous!");
