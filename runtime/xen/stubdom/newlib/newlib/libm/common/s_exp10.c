/* @(#)s_exp10.c 5.1 93/09/24 */
/* Modified from s_exp2.c by Yaakov Selkowitz 2007.  */

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
	<<exp10>>, <<exp10f>>---exponential
INDEX
	exp10
INDEX
	exp10f

ANSI_SYNOPSIS
	#include <math.h>
	double exp10(double <[x]>);
	float exp10f(float <[x]>);

TRAD_SYNOPSIS
	#include <math.h>
	double exp10(<[x]>);
	double <[x]>;

	float exp10f(<[x]>);
	float <[x]>;

DESCRIPTION
	<<exp10>> and <<exp10f>> calculate 10 ^ <[x]>, that is, 
	@ifnottex
	10 raised to the power <[x]>.
	@end ifnottex
	@tex
	$10^x$
	@end tex

	You can use the (non-ANSI) function <<matherr>> to specify
	error handling for these functions.

RETURNS
	On success, <<exp10>> and <<exp10f>> return the calculated value.
	If the result underflows, the returned value is <<0>>.  If the
	result overflows, the returned value is <<HUGE_VAL>>.  In
	either case, <<errno>> is set to <<ERANGE>>.

PORTABILITY
	<<exp10>> and <<exp10f>> are GNU extensions.

*/

/*
 * wrapper exp10(x)
 */

#undef exp10
#include "fdlibm.h"
#include <errno.h>
#include <math.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double exp10(double x)		/* wrapper exp10 */
#else
	double exp10(x)			/* wrapper exp10 */
	double x;
#endif
{
  return pow(10.0, x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
