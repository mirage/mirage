#include "headers/nearbyintf4.h"

static __inline float _nearbyintf(float x)
{
  return spu_extract(_nearbyintf4(spu_promote(x, 0)), 0);
}
