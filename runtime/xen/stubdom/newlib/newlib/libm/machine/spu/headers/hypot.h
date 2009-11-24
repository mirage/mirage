#include "headers/hypotd2.h"

static __inline double _hypot(double x, double y)
{
  return spu_extract(_hypotd2(spu_promote(x, 0), spu_promote(y, 0)), 0);
}
