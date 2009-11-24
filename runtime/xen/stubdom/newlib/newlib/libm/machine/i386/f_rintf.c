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
 * Fast math version of rintf(x)
 * Return x rounded to integral value according to the prevailing
 * rounding mode.
 * Method:
 *	Using inline x87 asms.
 * Exception:
 *	Governed by x87 FPCR.
 */

float _f_rintf (float x)
{
  float _result;
  asm ("frndint" : "=t" (_result) : "0" (x));
  return _result;
}

#endif  /* !__GNUC__ || _SOFT_FLOAT */

