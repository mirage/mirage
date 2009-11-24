#include "headers/powf4.h"

static __inline double _powf(float x, float y)
{
  return spu_extract(_powf4(spu_promote(x, 0), spu_promote(y, 0)), 0);
}
