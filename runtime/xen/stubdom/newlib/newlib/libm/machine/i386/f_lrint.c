/*
 * ====================================================
 * x87 FP implementation contributed to Newlib by
 * Dave Korn, November 2007.  This file is placed in the
 * public domain.  Permission to use, copy, modify, and 
 * distribute this software is freely granted.
 * ====================================================
 */

#if defined(__GNUC__) && !defined(_SOFT_FLOAT)

#include <math.h>

/*
FUNCTION
<<lrint>>, <<lrintf>>, <<lrintl>>---round and convert to long integer
INDEX
	lrint
INDEX
	lrintf
INDEX
	lrintl

ANSI_SYNOPSIS
	#include <math.h>
	long int lrint(double x);
        long int lrintf(float x);
        long int lrintl(long double x);

TRAD_SYNOPSIS
	ANSI-only.

DESCRIPTION
The <<lrint>>, <<lrintf>> and <<lrintl>> functions round <[x]> to the nearest integer value,
according to the current rounding direction. If the rounded value is outside the
range of the return type, the numeric result is unspecified. A range error may 
occur if the magnitude of <[x]> is too large.

RETURNS
These functions return the rounded integer value of <[x]>.
<<lrint>>, <<lrintf>> and <<lrintl>> return the result as a long integer.

PORTABILITY
<<lrint>>, <<lrintf>>, and <<lrintl>> are ANSI.
<<lrint>> and <<lrintf>> are available on all platforms.
<<lrintl>> is only available on i386 platforms when hardware 
floating point support is available and when compiling with GCC.

*/

/*
 * Fast math version of lrint(x)
 * Return x rounded to integral value according to the prevailing
 * rounding mode.
 * Method:
 *	Using inline x87 asms.
 * Exception:
 *	Governed by x87 FPCR.
 */

long int _f_lrint (double x)
{
  long int _result;
  asm ("fistpl %0" : "=m" (_result) : "t" (x) : "st");
  return _result;
}

#endif  /* !__GNUC__ || _SOFT_FLOAT */

