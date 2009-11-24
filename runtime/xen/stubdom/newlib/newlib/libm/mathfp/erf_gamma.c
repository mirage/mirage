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

/* gammaf_r(x, signgamp)
 * Reentrant version of the logarithm of the Gamma function 
 * with user provided pointer for the sign of Gamma(x). 
 *
 * Method: See lgammaf_r
 */

#include "fdlibm.h"

#ifdef __STDC__
	float gammaf_r(float x, int *signgamp)
#else
	float gammaf_r(x,signgamp)
	float x; int *signgamp;
#endif
{
	return expf (lgammaf_r(x,signgamp));
}

float gammaf(float x)
{
  return gammaf_r(x, &(_REENT_SIGNGAM(_REENT)));
}
