#include "headers/logd2.h"
#include "headers/dom_chkd_less_than.h"

static __inline double _log(double x)
{
  double res;
  vector double vx;
  vector double vc = { 0.0, 0.0 };

  vx = spu_promote(x, 0);
  res = spu_extract(_logd2(vx), 0);
#ifndef _IEEE_LIBM
  dom_chkd_less_than(vx, vc);
#endif
  return res;
}
