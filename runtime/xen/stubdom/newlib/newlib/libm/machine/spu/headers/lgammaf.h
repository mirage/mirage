#include "headers/lgammaf4.h"

static __inline float _lgammaf(float x)
{
  return spu_extract(_lgammaf4(spu_promote(x, 0)), 0);
}
