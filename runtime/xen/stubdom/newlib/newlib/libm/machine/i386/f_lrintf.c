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
 * Fast math version of lrintf(x)
 * Return x rounded to integral value according to the prevailing
 * rounding mode.
 * Method:
 *	Using inline x87 asms.
 * Exception:
 *	Governed by x87 FPCR.
 */

long int _f_lrintf (float x)
{
  long int _result;
  asm ("fistpl %0" : "=m" (_result) : "t" (x) : "st");
  return _result;
}

#endif  /* !__GNUC__ || _SOFT_FLOAT */

