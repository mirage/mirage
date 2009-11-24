#include "headers/acoshd2.h"
#include "headers/dom_chkd_less_than.h"

static __inline double _acosh(double x)
{
  double res;
  vector double vx;
  vector double vc = { 1.0, 1.0 };

  vx = spu_promote(x, 0);
  res = spu_extract(_acoshd2(vx), 0);
#ifndef _IEEE_LIBM
  dom_chkd_less_than(vx, vc);
#endif
  return res;
}
