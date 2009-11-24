#include "headers/lgammad2.h"

static __inline double _lgamma(double x)
{
  return spu_extract(_lgammad2(spu_promote(x, 0)), 0);
}
