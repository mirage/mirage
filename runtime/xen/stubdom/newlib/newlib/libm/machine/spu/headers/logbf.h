#include "headers/logbf4.h"

static __inline float _logbf(float x)
{
  return spu_extract(_logbf4(spu_promote(x, 0)), 0);
}
