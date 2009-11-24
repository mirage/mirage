#include "headers/signbitd2.h"

static __inline unsigned long long _signbit(double x)
{
  return spu_extract(_signbitd2(spu_promote(x, 0)), 0);
}
