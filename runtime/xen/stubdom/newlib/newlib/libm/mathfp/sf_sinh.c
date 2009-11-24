
/* @(#)z_sinhf.c 1.0 98/08/13 */
/******************************************************************
 * Hyperbolic Sine
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   hyperbolic sine of x
 *
 * Description:
 *   This routine returns the hyperbolic sine of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float
_DEFUN (sinhf, (float),
        float x)
{
  return (sinehf (x, 0));
}

#ifdef _DOUBLE_IS_32BITS

double sinh (double x)
{
  return (double) sinhf ((float) x);
}

#endif /* _DOUBLE_IS_32BITS */
