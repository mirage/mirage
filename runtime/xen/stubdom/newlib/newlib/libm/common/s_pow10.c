/* @(#)s_pow10.c 5.1 93/09/24 */
/* Modification from s_exp10.c Yaakov Selkowitz 2007.  */

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
	<<pow10>>, <<pow10f>>---exponential
INDEX
	pow10
INDEX
	pow10f

ANSI_SYNOPSIS
	#include <math.h>
	double pow10(double <[x]>);
	float pow10f(float <[x]>);

TRAD_SYNOPSIS
	#include <math.h>
	double pow10(<[x]>);
	double <[x]>;

	float pow10f(<[x]>);
	float <[x]>;

DESCRIPTION
	<<pow10>> and <<pow10f>> calculate 10 ^ <[x]>, that is, 
	@ifnottex
	10 raised to the power <[x]>.
	@end ifnottex
	@tex
	$10^x$
	@end tex

	You can use the (non-ANSI) function <<matherr>> to specify
	error handling for these functions.

RETURNS
	On success, <<pow10>> and <<pow10f>> return the calculated value.
	If the result underflows, the returned value is <<0>>.  If the
	result overflows, the returned value is <<HUGE_VAL>>.  In
	either case, <<errno>> is set to <<ERANGE>>.

PORTABILITY
	<<pow10>> and <<pow10f>> are GNU extensions.
*/

/*
 * wrapper pow10(x)
 */

#undef pow10
#include "fdlibm.h"
#include <errno.h>
#include <math.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double pow10(double x)		/* wrapper pow10 */
#else
	double pow10(x)			/* wrapper pow10 */
	double x;
#endif
{
  return pow(10.0, x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
