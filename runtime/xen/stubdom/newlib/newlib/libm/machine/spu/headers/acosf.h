#include "headers/acosf4.h"
#include "headers/dom_chkf_negone_one.h"

static __inline float _acosf(float x)
{
  float res;
  vector float vx;

  vx = spu_splats(x);
  res = spu_extract(_acosf4(vx), 0);
#ifndef _IEEE_LIBM
  /*
   * Domain error if not in the interval [-1, +1]
   */
  dom_chkf_negone_one(vx);
#endif
  return res;
}
