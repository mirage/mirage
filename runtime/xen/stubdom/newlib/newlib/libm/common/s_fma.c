#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double fma(double x, double y, double z)
#else
	double fma(x,y)
	double x;
	double y;
        double z;
#endif
{
  /* Implementation defined. */
  return (x * y) + z;
}

#endif /* _DOUBLE_IS_32BITS */
