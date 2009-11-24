/* wf_sinh.c -- float version of w_sinh.c.
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
 * wrapper sinhf(x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	float sinhf(float x)		/* wrapper sinhf */
#else
	float sinhf(x)			/* wrapper sinhf */
	float x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_sinhf(x);
#else
	float z; 
	struct exception exc;
	z = __ieee754_sinhf(x);
	if(_LIB_VERSION == _IEEE_) return z;
	if(!finitef(z)&&finitef(x)) {
	    /* sinhf(finite) overflow */
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;
	    
	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    exc.type = OVERFLOW;
	    exc.name = "sinhf";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
	    if (_LIB_VERSION == _SVID_)
	       exc.retval = ( (x>0.0) ? HUGE : -HUGE);
	    else
	       exc.retval = ( (x>0.0) ? HUGE_VAL : -HUGE_VAL);
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
	double sinh(double x)
#else
	double sinh(x)
	double x;
#endif
{
	return (double) sinhf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
