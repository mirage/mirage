#include "headers/sind2.h"

static __inline double _sin(double angle)
{
  return spu_extract(_sind2(spu_promote(angle, 0)), 0);
}
