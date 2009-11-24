/* sincos -- currently no more efficient than two separate calls to
   sin and cos. */
#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	void sincosf(float x, float *sinx, float *cosx)
#else
	void sincosf(x, sinx, cosx)
	float x;
        float *sinx;
        float *cosx;
#endif
{
  *sinx = sinf (x);
  *cosx = cosf (x);
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	void sincos(double x, double *sinx, double *cosx)
#else
	void sincos(x, sinx, cosx)
	double x;
        double sinx;
        double cosx;
#endif
{
  *sinx = sinf((float) x);
  *cosx = cosf((float) x);
}
#endif /* defined(_DOUBLE_IS_32BITS) */
