#include "headers/log1pf4.h"
#include "headers/dom_chkf_less_than.h"

static __inline float _log1pf(float x)
{
  float res;
  vector float vx;
  vector float vc = { -1.0, -1.0, -1.0, -1.0 };

  vx = spu_promote(x, 0);
  res = spu_extract(_log1pf4(vx), 0);
#ifndef _IEEE_LIBM
  dom_chkf_less_than(vx, vc);
#endif
  return res;
}
