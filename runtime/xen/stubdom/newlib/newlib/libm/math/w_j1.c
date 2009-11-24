
/* @(#)w_j1.c 5.1 93/09/24 */
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
 * wrapper of j1,y1 
 */

#include "fdlibm.h"
#include <errno.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double j1(double x)		/* wrapper j1 */
#else
	double j1(x)			/* wrapper j1 */
	double x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_j1(x);
#else
	double z;
	struct exception exc;
	z = __ieee754_j1(x);
	if(_LIB_VERSION == _IEEE_ || isnan(x) ) return z;
	if(fabs(x)>X_TLOSS) {
	    /* j1(|x|>X_TLOSS) */
            exc.type = TLOSS;
            exc.name = "j1";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = x;
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
	double y1(double x)		/* wrapper y1 */
#else
	double y1(x)			/* wrapper y1 */
	double x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_y1(x);
#else
	double z;
	struct exception exc;
	z = __ieee754_y1(x);
	if(_LIB_VERSION == _IEEE_ || isnan(x) ) return z;
        if(x <= 0.0){
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    /* y1(0) = -inf  or y1(x<0) = NaN */
	    exc.type = DOMAIN;	/* should be SING for IEEE */
	    exc.name = "y1";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = x;
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
            return exc.retval;              
        }
	if(x>X_TLOSS) {
	    /* y1(x>X_TLOSS) */
            exc.type = TLOSS;
            exc.name = "y1";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = x;
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

#endif /* defined(_DOUBLE_IS_32BITS) */





