#include "headers/atand2.h"

static __inline double _atan(double x)
{
  return spu_extract(_atand2(spu_promote(x, 0)), 0);
}
