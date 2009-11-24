/*
 * nan () returns a nan.
 * Added by Cygnus Support.
 */

/*
FUNCTION
	<<nan>>, <<nanf>>---representation of ``Not a Number''

INDEX
	nan
INDEX
	nanf

ANSI_SYNOPSIS
	#include <math.h>
	double nan(const char *);
	float nanf(const char *);

TRAD_SYNOPSIS
	#include <math.h>
	double nan();
	float nanf();


DESCRIPTION
	<<nan>> and <<nanf>> return an IEEE NaN (Not a Number) in
	double- and single-precision arithmetic respectively.  The
	argument is currently disregarded.

QUICKREF
	nan - pure

*/

#include "fdlibm.h"

#ifndef _DOUBLE_IS_32BITS

	double nan(const char *unused)
{
	double x;

	INSERT_WORDS(x,0x7ff80000,0);
	return x;
}

#endif /* _DOUBLE_IS_32BITS */
