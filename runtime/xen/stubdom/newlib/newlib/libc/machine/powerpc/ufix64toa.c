/* _ufix64toa_r: convert unsigned 64-bit fixed point to ASCII string.
 *
 * This routine converts an unsigned fixed-point number to long double format and
 * then calls _ldtoa_r to do the conversion.
 *
 * Written by Jeff Johnston.
 */

#ifdef __SPE__

#include <_ansi.h>
#include <limits.h>
#include <errno.h>
#include <stdlib.h>
#include <reent.h>
#include "fix64.h"

extern char *_simdldtoa_r _PARAMS((struct _reent *, LONG_DOUBLE_UNION *, int,
			       int, int *, int *, char **));

/*
 * Convert an unsigned fixed-point 64-bit value to string.
 *
 * Ignores `locale' stuff.
 */

char *
_DEFUN (_ufix64toa_r, (rptr, value, mode, ndigits, decpt, sign, rve),
	struct _reent *rptr _AND
	__uint64_t value _AND
	int mode _AND
	int ndigits _AND
	int *decpt _AND
	int *sign _AND
	char **rve)
{
  union long_double_union ldbl;
  union fix64_union fix64;
  unsigned long tmp;
  int exp, negexp;

  /* if input is 0, no additional work is needed */
  if (value == 0)
    {
      ldbl.i[0] = ldbl.i[1] = ldbl.i[2] = ldbl.i[3] = 0;
    }
  else /* otherwise, we calculate long double equivalent of value */
    {
      /* find exponent by locating most-significant one-bit */
      fix64.ll = value;
      negexp = 1;
      if (hiword(fix64) == 0)
	{
	  tmp = loword(fix64);
	  negexp = 33;
	}
      else
	{
	  tmp = hiword(fix64);
	  negexp = 1;
	}

      while (negexp < 65)
	{
	  if (tmp & 0x80000000)
	    break;
	  ++negexp;
	  tmp <<= 1;
	}
      
      /* shift input appropriately */
      fix64.ll = value << (negexp - 1 + (Exp_msk1 != 0));
      
      /* build long double */
      exp = -negexp + Bias;
      word0(ldbl) = (exp << Exp_shift);
      word1(ldbl) = hiword(fix64) << (32-Ebits-1);
      word2(ldbl) = loword(fix64) << (32-Ebits-1);
      word3(ldbl) = 0;
      if (Ebits+1 < 32)
	{
	  word0(ldbl) |= hiword(fix64) >> (Ebits + 1);
	  word1(ldbl) |= loword(fix64) >> (Ebits + 1);
	}
    }

  /* convert long double to character */
  return _simdldtoa_r (rptr, &ldbl, mode, ndigits, decpt, sign, rve);
}

#endif /* __SPE__ */
