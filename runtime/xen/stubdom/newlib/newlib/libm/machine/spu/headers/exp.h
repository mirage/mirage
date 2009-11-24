#include "headers/expd2.h"

static __inline double _exp(double x)
{
  return spu_extract(_expd2(spu_promote(x, 0)), 0);
}
