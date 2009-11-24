#include "headers/sincosd2.h"

static __inline void _sincos(double angle, double* sinx, double* cosx)
{
  vector double vsinx, vcosx;

  _sincosd2(spu_promote(angle, 0), &vsinx, &vcosx);
  *sinx = spu_extract(vsinx, 0);
  *cosx = spu_extract(vcosx, 0);
}
