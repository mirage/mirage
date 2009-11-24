#include "headers/acoshf4.h"
#include "headers/dom_chkf_less_than.h"

static __inline float _acoshf(float x)
{
  float res;
  vector float vx;
  vector float vc = { 1.0, 1.0, 1.0, 1.0 };

  vx = spu_promote(x, 0);
  res = spu_extract(_acoshf4(vx), 0);
#ifndef _IEEE_LIBM
  dom_chkf_less_than(vx, vc);
#endif
  return res;
}
