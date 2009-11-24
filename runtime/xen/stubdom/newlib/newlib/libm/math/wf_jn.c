/* wf_jn.c -- float version of w_jn.c.
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

#include "fdlibm.h"
#include <errno.h>


#ifdef __STDC__
	float jnf(int n, float x)	/* wrapper jnf */
#else
	float jnf(n,x)			/* wrapper jnf */
	float x; int n;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_jnf(n,x);
#else
	float z;
	struct exception exc;
	z = __ieee754_jnf(n,x);
	if(_LIB_VERSION == _IEEE_ || isnanf(x) ) return z;
	if(fabsf(x)>(float)X_TLOSS) {
	    /* jnf(|x|>X_TLOSS) */
            exc.type = TLOSS;
            exc.name = "jnf";
	    exc.err = 0;
	    exc.arg1 = (double)n;
	    exc.arg2 = (double)x;
            exc.retval = 0.0;
            if (_LIB_VERSION == _POSIX_)
                errno = ERANGE;
            else if (!matherr(&exc)) {
               errno = ERANGE;
            }        
	    if (exc.err != 0)
	       errno = exc.err;
            return exc.retval; 
	} else
	    return z;
#endif
}

#ifdef __STDC__
	float ynf(int n, float x)	/* wrapper ynf */
#else
	float ynf(n,x)			/* wrapper ynf */
	float x; int n;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_ynf(n,x);
#else
	float z;
	struct exception exc;
	z = __ieee754_ynf(n,x);
	if(_LIB_VERSION == _IEEE_ || isnanf(x) ) return z;
        if(x <= (float)0.0){
	    /* ynf(n,0) = -inf or ynf(x<0) = NaN */
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    exc.type = DOMAIN;	/* should be SING for IEEE */
	    exc.name = "ynf";
	    exc.err = 0;
	    exc.arg1 = (double)n;
	    exc.arg2 = (double)x;
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
	    /* ynf(x>X_TLOSS) */
            exc.type = TLOSS;
            exc.name = "ynf";
	    exc.err = 0;
	    exc.arg1 = (double)n;
	    exc.arg2 = (double)x;
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
	double jn(int n, double x)
#else
	double jn(n,x)
	double x; int n;
#endif
{
	return (double) jnf(n, (float) x);
}

#ifdef __STDC__
	double yn(int n, double x)
#else
	double yn(n,x)
	double x; int n;
#endif
{
	return (double) ynf(n, (float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
