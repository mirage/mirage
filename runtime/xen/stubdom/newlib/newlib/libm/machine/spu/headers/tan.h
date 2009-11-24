#include "headers/tand2.h"

static __inline double _tan(double angle)
{
  return spu_extract(_tand2(spu_promote(angle, 0)), 0);
}
