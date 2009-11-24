/* @(#)w_gamma.c 5.1 93/09/24 */
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

/* double gamma(double x)
 * Return  the logarithm of the Gamma function of x or the Gamma function of x,
 * depending on the library mode.
 */

#include <math.h>
#include <errno.h>

#ifdef __STDC__
	double tgamma(double x)
#else
	double tgamma(x)
	double x;
#endif
{
        double y;
	int local_signgam;
	y = gamma_r(x,&local_signgam);
	if (local_signgam < 0) y = -y;
#ifdef _IEEE_LIBM
	return y;
#else
	if(_LIB_VERSION == _IEEE_) return y;

	if(!finite(y)&&finite(x)) {
	  if(floor(x)==x&&x<=0.0)
            {
              /* tgamma pole */
              errno = EDOM;
              return HUGE_VAL;
            }
	  else
            {
              /* tgamma overflow */
              errno = ERANGE;
              return HUGE_VAL;
            }
	}
	return y;
#endif
}
