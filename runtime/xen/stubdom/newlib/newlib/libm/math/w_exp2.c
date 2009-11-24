
/* @(#)w_exp2.c 5.1 93/09/24 */
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
	<<exp2>>, <<exp2f>>---exponential
INDEX
	exp2
INDEX
	exp2f

ANSI_SYNOPSIS
	#include <math.h>
	double exp2(double <[x]>);
	float exp2f(float <[x]>);

TRAD_SYNOPSIS
	#include <math.h>
	double exp2(<[x]>);
	double <[x]>;

	float exp2f(<[x]>);
	float <[x]>;

DESCRIPTION
	<<exp2>> and <<exp2f>> calculate 2 ^ <[x]>, that is, 
	@ifnottex
	2 raised to the power <[x]>.
	@end ifnottex
	@tex
	$2^x$
	@end tex

	You can use the (non-ANSI) function <<matherr>> to specify
	error handling for these functions.

RETURNS
	On success, <<exp2>> and <<exp2f>> return the calculated value.
	If the result underflows, the returned value is <<0>>.  If the
	result overflows, the returned value is <<HUGE_VAL>>.  In
	either case, <<errno>> is set to <<ERANGE>>.

*/

/*
 * wrapper exp2(x)
 */

#include "fdlibm.h"
#include <errno.h>
#include <math.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double exp2(double x)		/* wrapper exp2 */
#else
	double exp2(x)			/* wrapper exp2 */
	double x;
#endif
{
  return pow(2.0, x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
