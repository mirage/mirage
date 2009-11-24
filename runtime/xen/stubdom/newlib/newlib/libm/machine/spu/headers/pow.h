#include "headers/powd2.h"

static __inline double _pow(double x, double y)
{
  return spu_extract(_powd2(spu_promote(x, 0), spu_promote(y, 0)), 0);
}
