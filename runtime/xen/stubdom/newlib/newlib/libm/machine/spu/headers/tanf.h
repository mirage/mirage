#include "headers/tanf4.h"

static __inline float _tanf(float angle)
{
  return spu_extract(_tanf4(spu_promote(angle, 0)), 0);
}
