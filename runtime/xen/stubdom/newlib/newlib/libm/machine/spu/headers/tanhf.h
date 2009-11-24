#include "headers/tanhf4.h"

static __inline float _tanhf(float x)
{
  return spu_extract(_tanhf4(spu_promote(x, 0)), 0);
}
