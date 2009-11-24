#include "headers/atan2f4.h"

static __inline float _atan2f(float y, float x)
{
  return spu_extract(_atan2f4(spu_promote(y, 0), spu_promote(x, 0)), 0);
}
