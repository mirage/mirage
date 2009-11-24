#include <errno.h>
#include "headers/truncf4.h"
#include "headers/tgammaf4.h"

static __inline float _tgammaf(float x)
{
  float res;
  vector float vx;
  vector float truncx;
  vector float vc = { 0.0, 0.0 };
  vector unsigned int cmpres;
  vector signed int verrno, ferrno;
  vector signed int fail = { EDOM, EDOM, EDOM, EDOM };

  vx = spu_promote(x, 0);
  res = spu_extract(_tgammaf4(vx), 0);
#ifndef _IEEE_LIBM
  /*
   * use vector truncf4 rather than splat x, and splat truncx.
   */
  truncx = _truncf4(vx);
  cmpres = spu_cmpeq(truncx, vx);
  verrno = spu_splats(errno);
  ferrno = spu_sel(verrno, fail, (vector unsigned int) cmpres);
  cmpres = spu_cmpgt(vc, vx);
  errno = spu_extract(spu_sel(verrno, ferrno, (vector unsigned int) cmpres), 0);
#endif
  return res;
}
