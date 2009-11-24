#include "headers/erff4.h"

static __inline float _erff(float x)
{
  return spu_extract(_erff4(spu_promote(x, 0)), 0);
}
