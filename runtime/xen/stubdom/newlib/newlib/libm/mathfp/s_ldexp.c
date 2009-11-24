
/* @(#)z_ldexp.c 1.0 98/08/13 */

/*
FUNCTION
       <<ldexp>>, <<ldexpf>>---load exponent

INDEX
        ldexp
INDEX
        ldexpf

ANSI_SYNOPSIS
       #include <math.h>
       double ldexp(double <[val]>, int <[exp]>);
       float ldexpf(float <[val]>, int <[exp]>);

TRAD_SYNOPSIS
       #include <math.h>

       double ldexp(<[val]>, <[exp]>)
              double <[val]>;
              int <[exp]>;

       float ldexpf(<[val]>, <[exp]>)
              float <[val]>;
              int <[exp]>;

DESCRIPTION
<<ldexp>> calculates the value
@ifnottex
<[val]> times 2 to the power <[exp]>.
@end ifnottex
@tex
$val\times 2^{exp}$.
@end tex
<<ldexpf>> is identical, save that it takes and returns <<float>>
rather than <<double>> values.

RETURNS
<<ldexp>> returns the calculated value.

Underflow and overflow both set <<errno>> to <<ERANGE>>.
On underflow, <<ldexp>> and <<ldexpf>> return 0.0.
On overflow, <<ldexp>> returns plus or minus <<HUGE_VAL>>.

PORTABILITY
<<ldexp>> is ANSI. <<ldexpf>> is an extension.

*/

/******************************************************************
 * ldexp
 *
 * Input:
 *   d - a floating point value
 *   e - an exponent value
 *
 * Output:
 *   A floating point value f such that f = d * 2 ^ e.
 *
 * Description:
 *   This function creates a floating point number f such that
 *   f = d * 2 ^ e.
 *
 *****************************************************************/

#include <float.h>
#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

#define DOUBLE_EXP_OFFS 1023

double
_DEFUN (ldexp, (double, int),
        double d _AND
        int e)
{
  int exp;
  __uint32_t hd;

  GET_HIGH_WORD (hd, d);

  /* Check for special values and then scale d by e. */
  switch (numtest (d))
    {
      case NAN:
        errno = EDOM;
        break;

      case INF:
        errno = ERANGE;
        break;

      case 0:
        break;

      default:
        exp = (hd & 0x7ff00000) >> 20;
        exp += e;

        if (exp > DBL_MAX_EXP + DOUBLE_EXP_OFFS)
         {
           errno = ERANGE;
           d = z_infinity.d;
         }
        else if (exp < DBL_MIN_EXP + DOUBLE_EXP_OFFS)
         {
           errno = ERANGE;
           d = -z_infinity.d;
         }
        else
         {
           hd &= 0x800fffff;
           hd |= exp << 20;
           SET_HIGH_WORD (d, hd);
         }
    }

    return (d);
}

#endif /* _DOUBLE_IS_32BITS */
