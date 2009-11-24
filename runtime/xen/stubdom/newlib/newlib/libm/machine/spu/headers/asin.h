#include "headers/asind2.h"
#include "headers/dom_chkd_negone_one.h"

static __inline double _asin(double x)
{
  double res;
  vector double vx;

  vx = spu_splats(x);
  res = spu_extract(_asind2(vx), 0);
#ifndef _IEEE_LIBM
  /*
   * Domain error if not in the interval [-1, +1]
   */
  dom_chkd_negone_one(vx);
#endif
  return res;
}
