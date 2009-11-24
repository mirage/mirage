/*
 * ====================================================
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunPro, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */


#include <math.h>
#include "fdlibm.h"

#ifdef __STDC__
	float nearbyintf(float x)
#else
	float nearbyintf(x)
	float x;
#endif
{
  return rintf(x);
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double nearbyint(double x)
#else
	double nearbyint(x)
	double x;
#endif
{
  return (double) nearbyintf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
