#include "headers/sincosf4.h"

static __inline void _sincosf(float angle, float* sinx, float* cosx)
{
  vector float vsinx, vcosx;

  _sincosf4(spu_promote(angle, 0), &vsinx, &vcosx);
  *sinx = spu_extract(vsinx, 0);
  *cosx = spu_extract(vcosx, 0);
}
