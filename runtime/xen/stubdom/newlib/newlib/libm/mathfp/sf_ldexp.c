
/* @(#)z_ldexpf.c 1.0 98/08/13 */
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

#define FLOAT_EXP_OFFS 127

float
_DEFUN (ldexpf, (float, int),
        float d _AND
        int e)
{
  int exp;
  __int32_t wd;

  GET_FLOAT_WORD (wd, d);

  /* Check for special values and then scale d by e. */
  switch (numtestf (wd))
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
        exp = (wd & 0x7f800000) >> 23;
        exp += e;

        if (exp > FLT_MAX_EXP + FLOAT_EXP_OFFS)
         {
           errno = ERANGE;
           d = z_infinity_f.f;
         }
        else if (exp < FLT_MIN_EXP + FLOAT_EXP_OFFS)
         {
           errno = ERANGE;
           d = -z_infinity_f.f;
         }
        else
         {
           wd &= 0x807fffff;
           wd |= exp << 23;
           SET_FLOAT_WORD (d, wd);
         }
    }

    return (d);
}

#ifdef _DOUBLE_IS_32BITS

double ldexp (double x, int e)
{
  return (double) ldexpf ((float) x, e);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
