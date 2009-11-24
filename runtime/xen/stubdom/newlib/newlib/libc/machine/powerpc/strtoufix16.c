/*
FUNCTION
        <<strtoufix16>>, <<strtoufix32>>, <<strtoufix64>>---string to signed fixed point

INDEX
	strtoufix16
INDEX
	strtoufix32
INDEX
	strtoufix64
INDEX
	_strtoufix16_r
INDEX
	_strtoufix32_r
INDEX
	_strtoufix64_r

ANSI_SYNOPSIS
	#include <stdlib.h>
        __uint16_t strtoufix16 (const char *<[s]>, char **<[ptr]>);

        __uint32_t strtoufix32 (const char *<[s]>, char **<[ptr]>);

        __uint64_t strtoufix64 (const char *<[s]>, char **<[ptr]>);

        __uint16_t _strtoufix16_r (void *<[reent]>, 
                       const char *<[s]>, char **<[ptr]>);

        __uint32_t _strtoufix32_r (void *<[reent]>, 
                       const char *<[s]>, char **<[ptr]>);

        __uint64_t _strtoufix64_r (void *<[reent]>, 
                       const char *<[s]>, char **<[ptr]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	__uint16_t strtoufix16 (<[s]>, <[ptr]>)
        char *<[s]>;
        char **<[ptr]>;

	__uint32_t strtoufix32 (<[s]>, <[ptr]>)
        char *<[s]>;
        char **<[ptr]>;

	__uint64_t strtoufix64 (<[s]>, <[ptr]>)
        char *<[s]>;
        char **<[ptr]>;

	__uint16_t _strtoufix16_r (<[reent]>, <[s]>, <[ptr]>)
	char *<[reent]>;
        char *<[s]>;
        char **<[ptr]>;

	__uint32_t _strtoufix32_r (<[reent]>, <[s]>, <[ptr]>)
	char *<[reent]>;
        char *<[s]>;
        char **<[ptr]>;

	__uint64_t _strtoufix64_r (<[reent]>, <[s]>, <[ptr]>)
	char *<[reent]>;
        char *<[s]>;
        char **<[ptr]>;

DESCRIPTION
        The function <<strtoufix16>> converts the string <<*<[s]>>> to
	a fixed-point 16-bits fraction representation.  The function 
	follows the same rules as <<strtod>>.

	The substring converted is the longest initial
	subsequence of <[s]>, beginning with the first
	non-whitespace character, that has the format:
	.[+|-]<[digits]>[.][<[digits]>][(e|E)[+|-]<[digits]>] 
	The substring contains no characters if <[s]> is empty, consists
	entirely of whitespace, or if the first non-whitespace
	character is something other than <<+>>, <<->>, <<.>>, or a
	digit. If the substring is empty, no conversion is done, and
	the value of <[s]> is stored in <<*<[ptr]>>>.  Otherwise,
	the substring is converted, and a pointer to the final string
	(which will contain at least the terminating null character of
	<[s]>) is stored in <<*<[ptr]>>>.  If you want no
	assignment to <<*<[ptr]>>>, pass a null pointer as <[ptr]>.

	<<strtoufix32>> is identical to <<strtoufix16>> except that it 
	converts to fixed-point 32-bit fraction representation.
	<<strtoufix64>> is also similar, except that it converts
	to fixed-point 64-bit fraction.

	The alternate functions <<_strtoufix16_r>>, <<_strtoufix32_r>>,
	and <<_strtoufix64_r>> are reentrant versions.
	The extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
	The functions return the converted substring value, if any.  If
	no conversion can be performed, then 0 is returned.  If the converted
	value is a NaN, 0 is returned and errno is set to <<EDOM>>.
	If the converted value exceeds the maximum positive unsigned fixed-point value, 
	the output value is saturated to the maximum value and <<ERANGE>> is stored in 
	errno.  If the converted value is less than 0, then the output is saturated to 0
	and <<ERANGE>> is stored in errno.  Otherwise, the converted value is returned in the
	specified fixed-point format.

PORTABILITY
        <<strtoufix16>>, <<strtoufix32>>, and <<strtoufix64>> are non-standard.

        The OS subroutines of <<strtod>> are required.
*/

#ifdef __SPE__

#include <_ansi.h>
#include <limits.h>
#include <errno.h>
#include <stdlib.h>
#include <reent.h>
#include "vfieeefp.h"

/*
 * Convert a string to a fixed-point 16-bit value.
 *
 * Ignores `locale' stuff.
 */
__uint16_t
_DEFUN (_strtoufix16_r, (rptr, nptr, endptr),
	struct _reent *rptr _AND
	_CONST char *nptr _AND
	char **endptr)
{
  union double_union dbl;
  unsigned long tmp, tmp2, result;
  int exp, negexp;

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
	return 0;
      return USHRT_MAX;
    }

  /* check for normal saturation */
  if (dbl.d >= 1.0)
    {
      rptr->_errno = ERANGE;
      return USHRT_MAX;
    }
  else if (dbl.d < 0)
    {
      rptr->_errno = ERANGE;
      return 0;
    }

  /* otherwise we have normal postive number in range */

  /* strip off exponent */
  exp = ((word0(dbl) & Exp_mask) >> Exp_shift) - Bias;
  negexp = -exp;
  if (negexp > 16)
    return 0;
  /* add in implicit normalized bit */
  tmp = word0(dbl) | Exp_msk1;
  /* remove exponent and sign */
  tmp <<= Ebits;
  /* perform rounding */
  tmp2 = tmp + (1 << (negexp + 14));
  result = tmp2 >> (negexp + 15);
  /* if rounding causes carry, must add carry bit in */
  if (tmp2 < tmp)
    {
      if (negexp == 0)
	{
	  /* we have overflow which means saturation */
	  rptr->_errno = ERANGE;
	  return USHRT_MAX;
	}
      result |= (1 << (16 - negexp));
    }

  return (__uint16_t)result;
}

#ifndef _REENT_ONLY

__uint16_t
_DEFUN (strtoufix16, (s, ptr, base),
	_CONST char *s _AND
	char **ptr)
{
  return _strtoufix16_r (_REENT, s, ptr);
}

#endif

#endif /* __SPE__ */
