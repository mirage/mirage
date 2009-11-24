#include "headers/coshf4.h"

static __inline float _coshf(float x)
{
  return spu_extract(_coshf4(spu_promote(x, 0)), 0);
}
