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
<<rint>>, <<rintf>>, <<rintl>>---round to integer
INDEX
	rint
INDEX
	rintf
INDEX
	rintl

ANSI_SYNOPSIS
	#include <math.h>
	double rint(double x);
        float rintf(float x);
        long double rintl(long double x);

TRAD_SYNOPSIS
	ANSI-only.

DESCRIPTION
The <<rint>>, <<rintf>> and <<rintl>> functions round <[x]> to an integer value
in floating-point format, using the current rounding direction.  They may
raise the inexact exception if the result differs in value from the argument.

RETURNS
These functions return the rounded integer value of <[x]>.

PORTABILITY
<<rint>>, <<rintf>> and <<rintl>> are ANSI.
<<rint>> and <<rintf>> are available on all platforms.
<<rintl>> is only available on i386 platforms when hardware 
floating point support is available and when compiling with GCC.

*/

/*
 * Fast math version of rint(x)
 * Return x rounded to integral value according to the prevailing
 * rounding mode.
 * Method:
 *	Using inline x87 asms.
 * Exception:
 *	Governed by x87 FPCR.
 */

double _f_rint (double x)
{
  double _result;
  asm ("frndint" : "=t" (_result) : "0" (x));
  return _result;
}

#endif  /* !__GNUC__ || _SOFT_FLOAT */

