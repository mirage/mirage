
/* @(#)w_acosh.c 5.1 93/09/24 */
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

/*
FUNCTION
<<acosh>>, <<acoshf>>---inverse hyperbolic cosine 

INDEX
acosh
INDEX
acoshf

ANSI_SYNOPSIS
	#include <math.h>
	double acosh(double <[x]>);
	float acoshf(float <[x]>);

TRAD_SYNOPSIS
	#include <math.h>
	double acosh(<[x]>)
	double <[x]>;

	float acoshf(<[x]>)
	float <[x]>;

DESCRIPTION
<<acosh>> calculates the inverse hyperbolic cosine of <[x]>.
<<acosh>> is defined as 
@ifnottex
. log(<[x]> + sqrt(<[x]>*<[x]>-1))
@end ifnottex
@tex
$$ln\Bigl(x + \sqrt{x^2-1}\Bigr)$$
@end tex

<[x]> must be a number greater than or equal to 1.

<<acoshf>> is identical, other than taking and returning floats.

RETURNS
<<acosh>> and <<acoshf>> return the calculated value.  If <[x]> 
less than 1, the return value is NaN and <<errno>> is set to <<EDOM>>.

You can change the error-handling behavior with the non-ANSI
<<matherr>> function.

PORTABILITY
Neither <<acosh>> nor <<acoshf>> are ANSI C.  They are not recommended
for portable programs.


QUICKREF ANSI SVID POSIX RENTRANT
 acos	 n,n,n,m
 acosf   n,n,n,m

MATHREF  
 acosh, NAN,   arg,DOMAIN,EDOM
 acosh, < 1.0, NAN,DOMAIN,EDOM
 acosh, >=1.0, acosh(arg),,,

MATHREF
 acoshf, NAN,   arg,DOMAIN,EDOM
 acoshf, < 1.0, NAN,DOMAIN,EDOM
 acoshf, >=1.0, acosh(arg),,,

*/

/* 
 * wrapper acosh(x)
 */

#include "fdlibm.h"
#include <errno.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double acosh(double x)		/* wrapper acosh */
#else
	double acosh(x)			/* wrapper acosh */
	double x;
#endif
{
#ifdef _IEEE_LIBM
	return __ieee754_acosh(x);
#else
	double z;
	struct exception exc;
	z = __ieee754_acosh(x);
	if(_LIB_VERSION == _IEEE_ || isnan(x)) return z;
	if(x<1.0) {
            /* acosh(x<1) */
            exc.type = DOMAIN;
            exc.name = "acosh";
	    exc.err = 0;
	    exc.arg1 = exc.arg2 = x;
            exc.retval = 0.0/0.0;
            if (_LIB_VERSION == _POSIX_)
               errno = EDOM;
            else if (!matherr(&exc)) {
               errno = EDOM;
            }
	    if (exc.err != 0)
	       errno = exc.err;
	    return exc.retval; 
	} else
	    return z;
#endif
}

#endif /* defined(_DOUBLE_IS_32BITS) */
