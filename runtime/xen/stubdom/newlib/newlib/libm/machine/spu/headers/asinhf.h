#include "headers/asinhf4.h"

static __inline float _asinhf(float x)
{
  return spu_extract(_asinhf4(spu_promote(x, 0)), 0);
}
