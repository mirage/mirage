#include "headers/isnanf4.h"

static __inline unsigned int _isnanf(float x)
{
  return spu_extract(_isnanf4(spu_promote(x, 0)), 0);
}
