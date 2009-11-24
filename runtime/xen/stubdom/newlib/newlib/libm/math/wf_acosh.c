/* wf_acosh.c -- float version of w_acosh.c.
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

/* 
 * wrapper acoshf(x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	float acoshf(float x)		/* wrapper acoshf */
#else
	float acoshf(x)			/* wrapper acoshf */
	float x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_acoshf(x);
#else
	float z;
	struct exception exc;
	z = __ieee754_acoshf(x);
	if(_LIB_VERSION == _IEEE_ || isnanf(x)) return z;
	if(x<(float)1.0) {
            /* acoshf(x<1) */
            exc.type = DOMAIN;
            exc.name = "acoshf";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
            exc.retval = 0.0/0.0;
            if (_LIB_VERSION == _POSIX_)
               errno = EDOM;
            else if (!matherr(&exc)) {
               errno = EDOM;
            }
	    if (exc.err != 0)
	       errno = exc.err;
	    return (float)exc.retval; 
	} else
	    return z;
#endif
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double acosh(double x)
#else
	double acosh(x)
	double x;
#endif
{
	return (double) acoshf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
