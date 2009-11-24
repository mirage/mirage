#ifdef __SPE__

#include <_ansi.h>
#include <limits.h>
#include <errno.h>
#include <stdlib.h>
#include <reent.h>
#include "vfieeefp.h"

/*
 * Convert a string to a fixed-point (sign + 31-bits) value.
 *
 * Ignores `locale' stuff.
 */
__int32_t
_DEFUN (_strtosfix32_r, (rptr, nptr, endptr),
	struct _reent *rptr _AND
	_CONST char *nptr _AND
	char **endptr)
{
  union double_union dbl;
  int exp, negexp, sign;
  unsigned long tmp, tmp2;
  long result = 0;

  dbl.d = _strtod_r (rptr, nptr, endptr);

  /* treat NAN as domain error, +/- infinity as saturation */
  if (!finite(dbl.d))
    {
      if (isnan (dbl.d))
	{
	  rptr->_errno = EDOM;
	  return 0;
	}
      rptr->_errno = ERANGE;
      if (word0(dbl) & Sign_bit)
	return LONG_MIN;
      return LONG_MAX;
    }

  /* check for normal saturation */
  if (dbl.d >= 1.0)
    {
      rptr->_errno = ERANGE;
      return LONG_MAX;
    }
  else if (dbl.d < -1.0)
    {
      rptr->_errno = ERANGE;
      return LONG_MIN;
    }

  /* otherwise we have normal number in range */

  /* strip off sign and exponent */
  sign = word0(dbl) & Sign_bit;
  exp = ((word0(dbl) & Exp_mask) >> Exp_shift) - Bias;
  negexp = -exp;
  if (negexp > 31)
    return 0;
  word0(dbl) &= ~(Exp_mask | Sign_bit);
  /* add in implicit normalized bit */
  word0(dbl) |= Exp_msk1;
  /* shift so result is contained in single word */
  tmp = word0(dbl) << Ebits;
  tmp |= ((unsigned long)word1(dbl) >> (32 - Ebits));
  if (negexp != 0)
    {
      /* perform rounding */
      tmp2 = tmp + (1 << (negexp - 1));
      result = (long)(tmp2 >> negexp);
      /* check if rounding caused carry bit which must be added into result */
      if (tmp2 < tmp)
	result |= (1 << (32 - negexp));
      /* check if positive saturation has occurred because of rounding */
      if (!sign && result < 0)
	{
	  rptr->_errno = ERANGE;
	  return LONG_MAX;
	}
    }
  else
    {
      /* we have -1.0, no rounding necessary */
      return LONG_MIN;
    }

  return sign ? -result : result;
}

#ifndef _REENT_ONLY

__int32_t
_DEFUN (strtosfix32, (s, ptr, base),
	_CONST char *s _AND
	char **ptr)
{
  return _strtosfix32_r (_REENT, s, ptr);
}

#endif

#endif /* __SPE__ */
