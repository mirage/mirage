/* wf_gamma.c -- float version of w_gamma.c.
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

#include "fdlibm.h"
#include <reent.h>
#include <errno.h>

#ifdef __STDC__
	float gammaf(float x)
#else
	float gammaf(x)
	float x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_gammaf_r(x,&(_REENT_SIGNGAM(_REENT)));
#else
        float y;
	struct exception exc;
        y = __ieee754_gammaf_r(x,&(_REENT_SIGNGAM(_REENT)));
        if(_LIB_VERSION == _IEEE_) return y;
        if(!finitef(y)&&finitef(x)) {
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    if(floorf(x)==x&&x<=(float)0.0) {
		/* gammaf(-integer) or gammaf(0) */
		exc.type = SING;
		exc.name = "gammaf";
		exc.err = 0;
		exc.arg1 = exc.arg2 = (double)x;
                if (_LIB_VERSION == _SVID_)
                  exc.retval = HUGE;
                else
                  exc.retval = HUGE_VAL;
		if (_LIB_VERSION == _POSIX_)
		  errno = EDOM;
		else if (!matherr(&exc)) {
		  errno = EDOM;
		}
            } else {
		/* gammaf(finite) overflow */
		exc.type = OVERFLOW;
		exc.name = "gammaf";
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
            }
	    if (exc.err != 0)
	       errno = exc.err;
	    return (float)exc.retval; 
        } else
            return y;
#endif
}             

#ifdef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double gamma(double x)
#else
	double gamma(x)
	double x;
#endif
{
	return (double) gammaf((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
