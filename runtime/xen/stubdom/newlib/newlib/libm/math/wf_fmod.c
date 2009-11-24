/* wf_fmod.c -- float version of w_fmod.c.
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
 * wrapper fmodf(x,y)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	float fmodf(float x, float y)	/* wrapper fmodf */
#else
	float fmodf(x,y)		/* wrapper fmodf */
	float x,y;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_fmodf(x,y);
#else
	float z;
	struct exception exc;
	z = __ieee754_fmodf(x,y);
	if(_LIB_VERSION == _IEEE_ ||isnanf(y)||isnanf(x)) return z;
	if(y==(float)0.0) {
            /* fmodf(x,0) */
            exc.type = DOMAIN;
            exc.name = "fmodf";
	    exc.err = 0;
	    exc.arg1 = (double)x;
	    exc.arg2 = (double)y;
            if (_LIB_VERSION == _SVID_)
               exc.retval = x;
	    else
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
	double fmod(double x, double y)
#else
	double fmod(x,y)
	double x,y;
#endif
{
	return (double) fmodf((float) x, (float) y);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
