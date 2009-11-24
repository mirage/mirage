
/* @(#)er_gamma.c 5.1 93/09/24 */
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

/* gamma_r(x, signgamp)
 * Reentrant version of the logarithm of the Gamma function 
 * with user provide pointer for the sign of Gamma(x). 
 *
 * Method: See lgamma_r
 */

#include "fdlibm.h"

#ifdef __STDC__
	double gamma_r(double x, int *signgamp)
#else
	double gamma_r(x,signgamp)
	double x; int *signgamp;
#endif
{
	return exp (lgamma_r(x,signgamp));
}

double gamma(double x)
{
  return gamma_r(x, &(_REENT_SIGNGAM(_REENT)));
}
