/* wf_hypot.c -- float version of w_hypot.c.
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
 * wrapper hypotf(x,y)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	float hypotf(float x, float y)	/* wrapper hypotf */
#else
	float hypotf(x,y)		/* wrapper hypotf */
	float x,y;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_hypotf(x,y);
#else
	float z;
	struct exception exc;
	z = __ieee754_hypotf(x,y);
	if(_LIB_VERSION == _IEEE_) return z;
	if((!finitef(z))&&finitef(x)&&finitef(y)) {
	    /* hypotf(finite,finite) overflow */
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    exc.type = OVERFLOW;
	    exc.name = "hypotf";
	    exc.err = 0;
	    exc.arg1 = (double)x;
	    exc.arg2 = (double)y;
	    if (_LIB_VERSION == _SVID_)
	       exc.retval = HUGE;
	    else
	       exc.retval = HUGE_VAL;
	    if (_LIB_VERSION == _POSIX_)
	       errno = ERANGE;
	    else if (!matherr(&exc)) {
	     	errno = ERANGE;
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
	double hypot(double x, double y)
#else
	double hypot(x,y)
	double x,y;
#endif
{
	return (double) hypotf((float) x, (float) y);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
