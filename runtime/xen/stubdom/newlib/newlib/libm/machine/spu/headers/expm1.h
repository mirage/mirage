#include "headers/expm1d2.h"

static __inline double _expm1(double x)
{
  return spu_extract(_expm1d2(spu_promote(x, 0)), 0);
}
