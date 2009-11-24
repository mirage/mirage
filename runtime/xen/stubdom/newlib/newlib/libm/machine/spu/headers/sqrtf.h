#include "headers/sqrtf4.h"
#include "headers/dom_chkf_less_than.h"

static __inline float _sqrtf(float in)
{
  float res;
  vector float vx;
  vector float vc = { 0.0, 0.0, 0.0, 0.0 };

  vx = spu_promote(in, 0);
  res = spu_extract(_sqrtf4(vx), 0);
#ifndef _IEEE_LIBM
  dom_chkf_less_than(vx, vc);
#endif
  return res;
}
