
/* @(#)s_frexp.c 5.1 93/09/24 */
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
       <<frexp>>, <<frexpf>>---split floating-point number
INDEX
	frexp
INDEX
	frexpf

ANSI_SYNOPSIS
	#include <math.h>
        double frexp(double <[val]>, int *<[exp]>);
        float frexpf(float <[val]>, int *<[exp]>);

TRAD_SYNOPSIS
	#include <math.h>
        double frexp(<[val]>, <[exp]>)
        double <[val]>;
        int *<[exp]>;

        float frexpf(<[val]>, <[exp]>)
        float <[val]>;
        int *<[exp]>;


DESCRIPTION
	All nonzero, normal numbers can be described as <[m]> * 2**<[p]>.
	<<frexp>> represents the double <[val]> as a mantissa <[m]>
	and a power of two <[p]>. The resulting mantissa will always
	be greater than or equal to <<0.5>>, and less than <<1.0>> (as
	long as <[val]> is nonzero). The power of two will be stored
	in <<*>><[exp]>. 

@ifnottex
<[m]> and <[p]> are calculated so that
<[val]> is <[m]> times <<2>> to the power <[p]>.
@end ifnottex
@tex
<[m]> and <[p]> are calculated so that
$ val = m \times 2^p $.
@end tex

<<frexpf>> is identical, other than taking and returning
floats rather than doubles.

RETURNS
<<frexp>> returns the mantissa <[m]>. If <[val]> is <<0>>, infinity,
or Nan, <<frexp>> will set <<*>><[exp]> to <<0>> and return <[val]>.

PORTABILITY
<<frexp>> is ANSI.
<<frexpf>> is an extension.


*/

/*
 * for non-zero x 
 *	x = frexp(arg,&exp);
 * return a double fp quantity x such that 0.5 <= |x| <1.0
 * and the corresponding binary exponent "exp". That is
 *	arg = x*2^exp.
 * If arg is inf, 0.0, or NaN, then frexp(arg,&exp) returns arg 
 * with *exp=0. 
 */

#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
static const double
#else
static double
#endif
two54 =  1.80143985094819840000e+16; /* 0x43500000, 0x00000000 */

#ifdef __STDC__
	double frexp(double x, int *eptr)
#else
	double frexp(x, eptr)
	double x; int *eptr;
#endif
{
	__int32_t hx, ix, lx;
	EXTRACT_WORDS(hx,lx,x);
	ix = 0x7fffffff&hx;
	*eptr = 0;
	if(ix>=0x7ff00000||((ix|lx)==0)) return x;	/* 0,inf,nan */
	if (ix<0x00100000) {		/* subnormal */
	    x *= two54;
	    GET_HIGH_WORD(hx,x);
	    ix = hx&0x7fffffff;
	    *eptr = -54;
	}
	*eptr += (ix>>20)-1022;
	hx = (hx&0x800fffff)|0x3fe00000;
	SET_HIGH_WORD(x,hx);
	return x;
}

#endif /* _DOUBLE_IS_32BITS */
