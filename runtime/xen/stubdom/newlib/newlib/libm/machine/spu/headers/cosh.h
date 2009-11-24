#include "headers/coshd2.h"

static __inline double _cosh(double x)
{
  return spu_extract(_coshd2(spu_promote(x, 0)), 0);
}
