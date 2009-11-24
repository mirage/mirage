#ifdef __SPE__

#include <_ansi.h>
#include <limits.h>
#include <errno.h>
#include <stdlib.h>
#include <reent.h>
#include "fix64.h"

/*
 * Convert a string to a fixed-point 64-bit unsigned value.
 *
 * Ignores `locale' stuff.
 */
__uint64_t
_DEFUN (_strtoufix64_r, (rptr, nptr, endptr),
	struct _reent *rptr _AND
	_CONST char *nptr _AND
	char **endptr)
{
  union long_double_union ldbl;
  int exp, sign, negexp, ld_type;
  __uint64_t tmp, tmp2, result = 0;

  init(ldbl);

  _simdstrtold ((char *)nptr, endptr, &ldbl);

  /* treat NAN as domain error, +/- infinity as saturation */
  ld_type = _simdldcheck (&ldbl);
  if (ld_type != 0)
    {
      if (ld_type == 1)
	{
	  rptr->_errno = EDOM;
	  return 0;
	}
      rptr->_errno = ERANGE;
      if (word0(ldbl) & Sign_bit)
	return 0;
      return ULONG_LONG_MAX;
    }

  /* strip off sign and exponent */
  sign = word0(ldbl) & Sign_bit;
  exp = ((word0(ldbl) & Exp_mask) >> Exp_shift) - Bias;
  negexp = -exp;
  if (negexp > 63)
    return 0;
  word0(ldbl) &= ~(Exp_mask | Sign_bit);
  /* add in implicit normalized bit */
  word0(ldbl) |= Exp_msk1;
  /* shift so result is contained in single word */
  tmp = word0(ldbl) << Ebits;
  tmp |= ((unsigned long)word1(ldbl) >> (32 - Ebits));
  tmp <<= 32;
  if (Ebits < 32)
    tmp |= ((unsigned long)word1(ldbl) << Ebits);
  tmp |= ((unsigned long)word2(ldbl) >> (32 - Ebits));

  /* check for saturation */
  if (sign)
    {
      rptr->_errno = ERANGE;
      return 0;
    }
  else
    {
      if (exp > 0 || (exp == 0 && tmp >= 0x8000000000000000LL))
	{
	  rptr->_errno = ERANGE;
	  return ULONG_LONG_MAX;
	}
    }

  /* otherwise we have normal number in range */
  if (negexp > 1)
    {
      tmp2 = tmp + (1 << (negexp - 2));
      result = (tmp2 >> (negexp - 1));
      /* if rounding causes carry, add carry bit in */
      if (tmp2 < tmp)
	result += 1 << (64 - negexp);
    }
  else
    {
      if (Ebits < 32)
	{
	  result = tmp + ((word2(ldbl) & (1 << (32 - Ebits - 1))) != 0);
	  /* if rounding causes carry, then saturation has occurred */
	  if (result < tmp)
	    {
	      rptr->_errno = ERANGE;
	      return ULONG_LONG_MAX;
	    }
	}
      else
	result = tmp;
    }

  return result;
}

#ifndef _REENT_ONLY

__uint64_t
_DEFUN (strtoufix64, (s, ptr, base),
	_CONST char *s _AND
	char **ptr)
{
  return _strtoufix64_r (_REENT, s, ptr);
}

#endif

#endif /* __SPE__ */
