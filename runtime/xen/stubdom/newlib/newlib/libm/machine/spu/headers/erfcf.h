#include "headers/erfcf4.h"

static __inline float _erfcf(float x)
{
  return spu_extract(_erfcf4(spu_promote(x, 0)), 0);
}
