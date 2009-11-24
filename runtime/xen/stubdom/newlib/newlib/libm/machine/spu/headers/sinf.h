#include "headers/sinf4.h"

static __inline float _sinf(float angle)
{
  return spu_extract(_sinf4(spu_promote(angle, 0)), 0);
}
