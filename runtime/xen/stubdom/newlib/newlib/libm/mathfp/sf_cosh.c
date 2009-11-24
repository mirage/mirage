
/* @(#)z_coshf.c 1.0 98/08/13 */
/******************************************************************
 * Hyperbolic Cosine
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   hyperbolic cosine of x
 *
 * Description:
 *   This routine returns the hyperbolic cosine of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float
_DEFUN (coshf, (float),
        float x)
{
  return (sinehf (x, 1));
}

#ifdef _DOUBLE_IS_32BITS
double cosh (double x)
{
  return (double) sinehf ((float) x, 1);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
