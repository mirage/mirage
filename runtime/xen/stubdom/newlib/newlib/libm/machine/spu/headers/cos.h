#include "headers/cosd2.h"

static __inline double _cos(double angle)
{
  return spu_extract(_cosd2(spu_promote(angle, 0)), 0);
}
