/* wf_j0.c -- float version of w_j0.c.
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
 * wrapper j0f(float x), y0f(float x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	float j0f(float x)		/* wrapper j0f */
#else
	float j0f(x)			/* wrapper j0f */
	float x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_j0f(x);
#else
	struct exception exc;
	float z = __ieee754_j0f(x);
	if(_LIB_VERSION == _IEEE_ || isnanf(x)) return z;
	if(fabsf(x)>(float)X_TLOSS) {
	    /* j0f(|x|>X_TLOSS) */
            exc.type = TLOSS;
            exc.name = "j0f";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
            exc.retval = 0.0;
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

#ifdef __STDC__
	float y0f(float x)		/* wrapper y0f */
#else
	float y0f(x)			/* wrapper y0f */
	float x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_y0f(x);
#else
	float z;
	struct exception exc;
	z = __ieee754_y0f(x);
	if(_LIB_VERSION == _IEEE_ || isnanf(x) ) return z;
        if(x <= (float)0.0){
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    /* y0f(0) = -inf  or y0f(x<0) = NaN */
	    exc.type = DOMAIN;	/* should be SING for IEEE y0f(0) */
	    exc.name = "y0f";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
	    if (_LIB_VERSION == _SVID_)
	       exc.retval = -HUGE;
	    else
	       exc.retval = -HUGE_VAL;
	    if (_LIB_VERSION == _POSIX_)
	       errno = EDOM;
	    else if (!matherr(&exc)) {
	       errno = EDOM;
	    }
	    if (exc.err != 0)
	       errno = exc.err;
            return (float)exc.retval; 
        }
	if(x>(float)X_TLOSS) {
	    /* y0f(x>X_TLOSS) */
            exc.type = TLOSS;
            exc.name = "y0f";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
            exc.retval = 0.0;
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
	double j0(double x)
#else
	double j0(x)
	double x;
#endif
{
	return (double) j0f((float) x);
}

#ifdef __STDC__
	double y0(double x)
#else
	double y0(x)
	double x;
#endif
{
	return (double) y0f((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
