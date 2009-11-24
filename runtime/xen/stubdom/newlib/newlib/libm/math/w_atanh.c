
/* @(#)w_atanh.c 5.1 93/09/24 */
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
	<<atanh>>, <<atanhf>>---inverse hyperbolic tangent 

INDEX
	atanh
INDEX
	atanhf

ANSI_SYNOPSIS
	#include <math.h>
	double atanh(double <[x]>);
	float atanhf(float <[x]>);

TRAD_SYNOPSIS
	#include <math.h>
	double atanh(<[x]>)
	double <[x]>;

	float atanhf(<[x]>)
	float <[x]>;

DESCRIPTION
	<<atanh>> calculates the inverse hyperbolic tangent of <[x]>.

	<<atanhf>> is identical, other than taking and returning
	<<float>> values.

RETURNS
	<<atanh>> and <<atanhf>> return the calculated value.

	If 
	@ifnottex
	|<[x]>|
	@end ifnottex
	@tex
	$|x|$
	@end tex
	is greater than 1, the global <<errno>> is set to <<EDOM>> and
	the result is a NaN.  A <<DOMAIN error>> is reported.

	If 
	@ifnottex
	|<[x]>|
	@end ifnottex
	@tex
	$|x|$
	@end tex
	is 1, the global <<errno>> is set to <<EDOM>>; and the result is 
	infinity with the same sign as <<x>>.  A <<SING error>> is reported.

	You can modify the error handling for these routines using
	<<matherr>>.

PORTABILITY
	Neither <<atanh>> nor <<atanhf>> are ANSI C.

QUICKREF
	atanh - pure
	atanhf - pure


*/

/* 
 * wrapper atanh(x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double atanh(double x)		/* wrapper atanh */
#else
	double atanh(x)			/* wrapper atanh */
	double x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_atanh(x);
#else
	double z,y;
	struct exception exc;
	z = __ieee754_atanh(x);
	if(_LIB_VERSION == _IEEE_ || isnan(x)) return z;
	y = fabs(x);
	if(y>=1.0) {
	    if(y>1.0) {
                /* atanh(|x|>1) */
                exc.type = DOMAIN;
                exc.name = "atanh";
		exc.err = 0;
		exc.arg1 = exc.arg2 = x;
                exc.retval = 0.0/0.0;
                if (_LIB_VERSION == _POSIX_)
                  errno = EDOM;
                else if (!matherr(&exc)) {
                  errno = EDOM;
                }
	    } else { 
                /* atanh(|x|=1) */
                exc.type = SING;
                exc.name = "atanh";
		exc.err = 0;
		exc.arg1 = exc.arg2 = x;
		exc.retval = x/0.0;	/* sign(x)*inf */
                if (_LIB_VERSION == _POSIX_)
                  errno = EDOM;
                else if (!matherr(&exc)) {
                  errno = EDOM;
                }
            }
	    if (exc.err != 0)
              errno = exc.err;
            return exc.retval; 
	} else
	    return z;
#endif
}

#endif /* defined(_DOUBLE_IS_32BITS) */




