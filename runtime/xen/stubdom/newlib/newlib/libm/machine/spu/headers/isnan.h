#include "headers/isnand2.h"

static __inline int _isnan(double x)
{
  return spu_extract(_isnand2(spu_promote(x, 0)), 0);
}
