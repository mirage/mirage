/* wrf_gamma.c -- float version of wr_gamma.c.
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
 * wrapper float gammaf_r(float x, int *signgamp)
 */

#include "fdlibm.h"
#include <errno.h>

#ifdef __STDC__
	float gammaf_r(float x, int *signgamp) /* wrapper lgammaf_r */
#else
	float gammaf_r(x,signgamp)              /* wrapper lgammaf_r */
	float x; int *signgamp;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_gammaf_r(x,signgamp);
#else
        float y;
	struct exception exc;
        y = __ieee754_gammaf_r(x,signgamp);
        if(_LIB_VERSION == _IEEE_) return y;
        if(!finitef(y)&&finitef(x)) {
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    exc.name = "gammaf";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = (double)x;
            if (_LIB_VERSION == _SVID_)
                exc.retval = HUGE;
            else
                exc.retval = HUGE_VAL;
            if(floorf(x)==x&&x<=(float)0.0) {
		/* gammaf(-integer) or gamma(0) */
		exc.type = SING;
		if (_LIB_VERSION == _POSIX_)
		  errno = EDOM;
		else if (!matherr(&exc)) {
		  errno = EDOM;
		}
            } else {
		/* gammaf(finite) overflow */
		exc.type = OVERFLOW;
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
