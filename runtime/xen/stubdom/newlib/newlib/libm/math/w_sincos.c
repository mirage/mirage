/* sincos -- currently no more efficient than two separate calls to
   sin and cos. */

#include "fdlibm.h"
#include <errno.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	void sincos(double x, double *sinx, double *cosx)
#else
	void sincos(x, sinx, cosx)
	double x;
        double *sinx;
        double *cosx;
#endif
{
  *sinx = sin (x);
  *cosx = cos (x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
