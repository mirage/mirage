#include "headers/sinhf4.h"

static __inline float _sinhf(float x)
{
  return spu_extract(_sinhf4(spu_promote(x, 0)), 0);
}
