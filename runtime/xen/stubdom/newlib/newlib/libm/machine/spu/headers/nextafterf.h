#include "headers/nextafterf4.h"

static __inline float _nextafterf(float x, float y)
{
  return spu_extract(_nextafterf4(spu_promote(x, 0), spu_promote(y, 0)), 0);
}
