/* erf_gamma.c -- float version of er_gamma.c.
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
 *
 */

/* __ieee754_gammaf_r(x, signgamp)
 * Reentrant version of the logarithm of the Gamma function 
 * with user provide pointer for the sign of Gamma(x). 
 *
 * Method: See __ieee754_lgammaf_r
 */

#include "fdlibm.h"

#ifdef __STDC__
	float __ieee754_gammaf_r(float x, int *signgamp)
#else
	float __ieee754_gammaf_r(x,signgamp)
	float x; int *signgamp;
#endif
{
	return __ieee754_expf (__ieee754_lgammaf_r(x,signgamp));
}
