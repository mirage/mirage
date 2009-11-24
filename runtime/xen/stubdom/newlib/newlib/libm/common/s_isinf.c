/*
 * isinf(x) returns 1 if x is infinity, else 0;
 * no branching!
 *
 * isinf is a <math.h> macro in the C99 standard.  It was previously
 * implemented as a function by newlib and is declared as such in
 * <ieeefp.h>.  Newlib supplies it here as a function if the user
 * chooses to use <ieeefp.h> or needs to link older code compiled with the
 * previous <math.h> declaration.
 */

#include "fdlibm.h"
#include <ieeefp.h>

#ifndef _DOUBLE_IS_32BITS

int
_DEFUN (isinf, (x),
	double x)
{
	__int32_t hx,lx;
	EXTRACT_WORDS(hx,lx,x);
	hx &= 0x7fffffff;
	hx |= (__uint32_t)(lx|(-lx))>>31;	
	hx = 0x7ff00000 - hx;
	return 1 - (int)((__uint32_t)(hx|(-hx))>>31);
}

#endif /* _DOUBLE_IS_32BITS */
