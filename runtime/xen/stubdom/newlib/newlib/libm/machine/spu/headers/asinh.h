#include "headers/asinhd2.h"

static __inline double _asinh(double x)
{
  return spu_extract(_asinhd2(spu_promote(x, 0)), 0);
}
