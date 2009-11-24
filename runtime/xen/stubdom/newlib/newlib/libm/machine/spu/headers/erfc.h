#include "headers/erfcd2.h"

static __inline double _erfc(double x)
{
  return spu_extract(_erfcd2(spu_promote(x, 0)), 0);
}
