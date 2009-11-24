#include "headers/hypotf4.h"

static __inline float _hypotf(float x, float y)
{
  return spu_extract(_hypotf4(spu_promote(x, 0), spu_promote(y, 0)), 0);
}
