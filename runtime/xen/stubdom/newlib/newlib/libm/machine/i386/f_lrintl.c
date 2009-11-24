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
 * Fast math version of lrintl(x)
 * Return x rounded to integral value according to the prevailing
 * rounding mode.
 * Method:
 *	Using inline x87 asms.
 * Exception:
 *	Governed by x87 FPCR.
 */

long int _f_lrintl (long double x)
{
  long int _result;
  asm ("fistpl %0" : "=m" (_result) : "t" (x) : "st");
  return _result;
}

/* For now, there is only the fast math version so we use it.  */
long int lrintl (long double x) {
  return _f_lrintl(x);
}

#endif /* !_SOFT_FLOAT */
#endif /* __GNUC__ */
