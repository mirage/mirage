/* sf_signif.c -- float version of s_signif.c.
 * Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
 */

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

#include "fdlibm.h"

#ifdef __STDC__
	float significandf(float x)
#else
	float significandf(x)
	float x;
#endif
{
	return scalbf(x,(float) -ilogbf(x));
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double significand(double x)
#else
	double significand(x)
	double x;
#endif
{
	return (double) significandf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
