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
 * Fast math version of rintl(x)
 * Return x rounded to integral value according to the prevailing
 * rounding mode.
 * Method:
 *	Using inline x87 asms.
 * Exception:
 *	Governed by x87 FPCR.
 */

long double _f_rintl (long double x)
{
  long double _result;
  asm ("frndint" : "=t" (_result) : "0" (x));
  return _result;
}

/* For now, we only have the fast math version.  */
long double rintl (long double x) {
  return _f_rintl(x);
} 

#endif /* !_SOFT_FLOAT */
#endif /* __GNUC__ */
