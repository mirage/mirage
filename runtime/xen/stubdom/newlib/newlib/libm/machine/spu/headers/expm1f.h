#include "headers/expm1f4.h"

static __inline float _expm1f(float vx)
{
  return spu_extract(_expm1f4(spu_promote(vx, 0)), 0);
}
