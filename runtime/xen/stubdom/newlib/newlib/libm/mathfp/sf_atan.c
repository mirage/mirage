
/* @(#)z_atanf.c 1.0 98/08/13 */
/******************************************************************
 * Arctangent
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   arctan of x
 *
 * Description:
 *   This routine returns the arctan of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float
_DEFUN (atanf, (float),
        float x)
{
  switch (numtestf (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        /* this should check to see if neg NaN or pos NaN... */
        return (__PI_OVER_TWO);
      case 0:
        return (0.0);
      default:
        return (atangentf (x, 0, 0, 0));
    }
}

#ifdef _DOUBLE_IS_32BITS
double atan (double x)
{
  return (double) atangentf ((float) x, 0, 0, 0);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
