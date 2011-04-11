#include <math.h>

int finite(double d) {
  return isinf(d)==0 && isnan(d)==0;
}

int __finite(double d) __attribute__((alias("finite")));
