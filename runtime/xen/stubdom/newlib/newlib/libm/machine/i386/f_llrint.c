/*
 * ====================================================
 * x87 FP implementation contributed to Newlib by
 * Dave Korn, November 2007.  This file is placed in the
 * public domain.  Permission to use, copy, modify, and 
 * distribute this software is freely granted.
 * ====================================================
 */

#ifdef __GNUC__
#if !defined(_SOFT_FLOAT)

#include <math.h>

/*
FUNCTION
<<llrint>>, <<llrintf>>, <<llrintl>>---round and convert to long long integer
INDEX
	llrint
INDEX
	llrintf
INDEX
	llrintl

ANSI_SYNOPSIS
	#include <math.h>
	long long int llrint(double x);
        long long int llrintf(float x);
        long long int llrintl(long double x);

TRAD_SYNOPSIS
	ANSI-only.

DESCRIPTION
The <<llrint>>, <<llrintf>> and <<llrintl>> functions round <[x]> to the nearest integer value,
according to the current rounding direction. If the rounded value is outside the
range of the return type, the numeric result is unspecified. A range error may 
occur if the magnitude of <[x]> is too large.

RETURNS
These functions return the rounded integer value of <[x]>.
<<llrint>>, <<llrintf>> and <<llrintl>> return the result as a long long integer.

PORTABILITY
<<llrint>>, <<llrintf>> and <<llrintl>> are ANSI.
<<llrint>>, <<llrintf>> and <<llrintl>> are only available on i386 platforms when
hardware floating point support is available and when compiling with GCC.

*/

/*
 * Fast math version of llrint(x)
 * Return x rounded to integral value according to the prevailing
 * rounding mode.
 * Method:
 *	Using inline x87 asms.
 * Exception:
 *	Governed by x87 FPCR.
 */

long long int _f_llrint (double x)
{
  long long int _result;
  asm ("fistpll %0" : "=m" (_result) : "t" (x) : "st");
  return _result;
}

/* For now, we only have the fast math version.  */
long long int llrint (double x) {
  return _f_llrint(x);
}

#endif /* !_SOFT_FLOAT */
#endif /* __GNUC__ */
