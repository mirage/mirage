#include <errno.h>
#include "headers/truncd2.h"
#include "headers/tgammad2.h"

static __inline double _tgamma(double x)
{
  double res;
  vector double vx;
  vector double truncx;
  vector double vc = { 0.0, 0.0 };
  vector unsigned long long cmpres;
  vector signed int verrno, ferrno;
  vector signed int fail = { EDOM, EDOM, EDOM, EDOM };

  vx = spu_promote(x, 0);
  res = spu_extract(_tgammad2(vx), 0);

#ifndef _IEEE_LIBM
  /*
   * use vector truncd2 rather than splat x, and splat truncx.
   */
  truncx = _truncd2(vx);
  cmpres = spu_cmpeq(truncx, vx);
  verrno = spu_splats(errno);
  ferrno = spu_sel(verrno, fail, (vector unsigned int) cmpres);
  cmpres = spu_cmpgt(vc, vx);
  errno = spu_extract(spu_sel(verrno, ferrno, (vector unsigned int) cmpres), 0);
#endif
  return res;
}
