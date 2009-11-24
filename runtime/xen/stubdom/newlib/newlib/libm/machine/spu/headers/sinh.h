#include "headers/sinhd2.h"

static __inline double _sinh(double x)
{
  return spu_extract(_sinhd2(spu_promote(x, 0)), 0);
}
