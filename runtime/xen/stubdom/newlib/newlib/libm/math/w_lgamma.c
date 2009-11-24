
/* @(#)w_lgamma.c 5.1 93/09/24 */
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

/* double lgamma(double x)
 * Return the logarithm of the Gamma function of x.
 *
 * Method: call __ieee754_lgamma_r
 */

#include "fdlibm.h"
#include <reent.h>
#include <errno.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double lgamma(double x)
#else
	double lgamma(x)
	double x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_lgamma_r(x,&(_REENT_SIGNGAM(_REENT)));
#else
        double y;
	struct exception exc;
        y = __ieee754_lgamma_r(x,&(_REENT_SIGNGAM(_REENT)));
        if(_LIB_VERSION == _IEEE_) return y;
        if(!finite(y)&&finite(x)) {
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    exc.name = "lgamma";
	    exc.err = 0;
	    exc.arg1 = x;
	    exc.arg2 = x;
            if (_LIB_VERSION == _SVID_)
               exc.retval = HUGE;
            else
               exc.retval = HUGE_VAL;
	    if(floor(x)==x&&x<=0.0) {
		/* lgamma(-integer) */
		exc.type = SING;
		if (_LIB_VERSION == _POSIX_)
		   errno = EDOM;
		else if (!matherr(&exc)) {
		   errno = EDOM;
		}

            } else {
		/* lgamma(finite) overflow */
		exc.type = OVERFLOW;
                if (_LIB_VERSION == _POSIX_)
		   errno = ERANGE;
                else if (!matherr(&exc)) {
                   errno = ERANGE;
		}
            }
	    if (exc.err != 0)
	       errno = exc.err;
            return exc.retval; 
        } else
            return y;
#endif
}             

#endif /* defined(_DOUBLE_IS_32BITS) */







