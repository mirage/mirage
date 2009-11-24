#include "headers/cosf4.h"

static __inline float _cosf(float angle)
{
  return spu_extract(_cosf4(spu_promote(angle, 0)), 0);
}
