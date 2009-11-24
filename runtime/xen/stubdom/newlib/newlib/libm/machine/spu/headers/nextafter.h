#include "headers/nextafterd2.h"

static __inline double _nextafter(double x, double y)
{
  return spu_extract(_nextafterd2(spu_promote(x, 0), spu_promote(y, 0)), 0);
}
