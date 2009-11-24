#include "headers/erfd2.h"

static __inline double _erf(double x)
{
  return spu_extract(_erfd2(spu_promote(x, 0)), 0);
}
