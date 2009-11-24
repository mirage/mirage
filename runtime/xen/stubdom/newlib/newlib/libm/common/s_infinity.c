/*
 * infinity () returns the representation of infinity.
 * Added by Cygnus Support.
 */

/*
FUNCTION
	<<infinity>>, <<infinityf>>---representation of infinity

INDEX
	infinity
INDEX
	infinityf

ANSI_SYNOPSIS
	#include <math.h>
	double infinity(void);
	float infinityf(void);

TRAD_SYNOPSIS
	#include <math.h>
	double infinity();
	float infinityf();


DESCRIPTION
	<<infinity>> and <<infinityf>> return the special number IEEE
	infinity in double- and single-precision arithmetic
	respectively.

QUICKREF
	infinity - pure

*/

#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

	double infinity()
{
	double x;

	INSERT_WORDS(x,0x7ff00000,0);
	return x;
}

#endif /* _DOUBLE_IS_32BITS */
