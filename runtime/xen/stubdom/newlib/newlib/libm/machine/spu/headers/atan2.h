#include "headers/atan2d2.h"

static __inline double _atan2(double y, double x)
{
  return spu_extract(_atan2d2(spu_promote(y, 0), spu_promote(x, 0)), 0);
}
