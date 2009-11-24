#include "headers/rintf4.h"

static __inline float _rintf(float x)
{
  return spu_extract(_rintf4(spu_promote(x, 0)), 0);
}
