/* wf_exp.c -- float version of w_exp.c.
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
 * wrapper expf(x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
static const float
#else
static float
#endif
o_threshold=  8.8721679688e+01,  /* 0x42b17180 */
u_threshold= -1.0397208405e+02;  /* 0xc2cff1b5 */

#ifdef __STDC__
	float expf(float x)		/* wrapper expf */
#else
	float expf(x)			/* wrapper expf */
	float x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_expf(x);
#else
	float z;
	struct exception exc;
	z = __ieee754_expf(x);
	if(_LIB_VERSION == _IEEE_) return z;
	if(finitef(x)) {
	    if(x>o_threshold) {
		/* expf(finite) overflow */
#ifndef HUGE_VAL
#define HUGE_VAL inf
	        double inf = 0.0;

	        SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
		exc.type = OVERFLOW;
		exc.name = "expf";
		exc.err = 0;
		exc.arg1 = exc.arg2 = (double)x;
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
	        return exc.retval; 
	    } else if(x<u_threshold) {
		/* expf(finite) underflow */
		exc.type = UNDERFLOW;
		exc.name = "expf";
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
	        return exc.retval; 
	    } 
	} 
	return z;
#endif
}

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double exp(double x)
#else
	double exp(x)
	double x;
#endif
{
	return (double) expf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
