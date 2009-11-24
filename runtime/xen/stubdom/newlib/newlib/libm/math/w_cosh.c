
/* @(#)w_cosh.c 5.1 93/09/24 */
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

FUNCTION
        <<cosh>>, <<coshf>>---hyperbolic cosine

ANSI_SYNOPSIS
        #include <math.h>
        double cosh(double <[x]>);
        float coshf(float <[x]>)

TRAD_SYNOPSIS
        #include <math.h>
        double cosh(<[x]>)
        double <[x]>;

        float coshf(<[x]>)
        float <[x]>;

DESCRIPTION

	<<cosh>> computes the hyperbolic cosine of the argument <[x]>.
	<<cosh(<[x]>)>> is defined as 
	@ifnottex
	. (exp(x) + exp(-x))/2
	@end ifnottex
	@tex
	$${(e^x + e^{-x})} \over 2$$
	@end tex

	Angles are specified in radians.  
		
	<<coshf>> is identical, save that it takes and returns <<float>>.

RETURNS
	The computed value is returned.  When the correct value would create
	an overflow,  <<cosh>> returns the value <<HUGE_VAL>> with the
	appropriate sign, and the global value <<errno>> is set to <<ERANGE>>.

	You can modify error handling for these functions using the
	function <<matherr>>.

PORTABILITY
	<<cosh>> is ANSI.  
	<<coshf>> is an extension.

QUICKREF
	cosh ansi pure
	coshf - pure
*/

/* 
 * wrapper cosh(x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifndef _DOUBLE_IS_32BITS
 
#ifdef __STDC__
	double cosh(double x)		/* wrapper cosh */
#else
	double cosh(x)			/* wrapper cosh */
	double x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_cosh(x);
#else
	double z;
	struct exception exc;
	z = __ieee754_cosh(x);
	if(_LIB_VERSION == _IEEE_ || isnan(x)) return z;
	if(fabs(x)>7.10475860073943863426e+02) {	
	    /* cosh(finite) overflow */
#ifndef HUGE_VAL
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    exc.type = OVERFLOW;
	    exc.name = "cosh";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = x;
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
	} else
	    return z;
#endif
}

#endif /* defined(_DOUBLE_IS_32BITS) */
