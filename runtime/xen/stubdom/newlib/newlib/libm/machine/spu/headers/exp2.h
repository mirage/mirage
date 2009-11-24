#include "headers/exp2d2.h"

static __inline double _exp2(double vx)
{
  return spu_extract(_exp2d2(spu_promote(vx, 0)), 0);
}
