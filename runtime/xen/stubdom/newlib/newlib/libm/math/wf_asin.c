/* wf_asin.c -- float version of w_asin.c.
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
 * wrapper asinf(x)
 */


#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	float asinf(float x)		/* wrapper asinf */
#else
	float asinf(x)			/* wrapper asinf */
	float x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_asinf(x);
#else
	float z;
	struct exception exc;
	z = __ieee754_asinf(x);
	if(_LIB_VERSION == _IEEE_ || isnanf(x)) return z;
	if(fabsf(x)>(float)1.0) {
	    /* asinf(|x|>1) */
	    exc.type = DOMAIN;
	    exc.name = "asinf";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
	    exc.retval = nan("");
	    if(_LIB_VERSION == _POSIX_)
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
	double asin(double x)
#else
	double asin(x)
	double x;
#endif
{
	return (double) asinf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
