/* wf_acos.c -- float version of w_acos.c.
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
 * wrap_acosf(x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef _HAVE_STDC
	float acosf(float x)		/* wrapper acosf */
#else
	float acosf(x)			/* wrapper acosf */
	float x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_acosf(x);
#else
	float z;
	struct exception exc;
	z = __ieee754_acosf(x);
	if(_LIB_VERSION == _IEEE_ || isnanf(x)) return z;
	if(fabsf(x)>(float)1.0) {
	    /* acosf(|x|>1) */
	    exc.type = DOMAIN;
	    exc.name = "acosf";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
	    exc.retval = nan("");
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
	double acos(double x)
#else
	double acos(x)
	double x;
#endif
{
	return (double) acosf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
