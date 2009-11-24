/* wf_exp2.c -- float version of w_exp2.c.
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

/* 
 * wrapper exp2f(x)
 */

#include "fdlibm.h"
#include <errno.h>
#include <math.h>

#ifdef __STDC__
	float exp2f(float x)		/* wrapper exp2f */
#else
	float exp2f(x)			/* wrapper exp2f */
	float x;
#endif
{
  return powf(2.0, x);
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double exp2(double x)
#else
	double exp2(x)
	double x;
#endif
{
	return (double) exp2f((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
