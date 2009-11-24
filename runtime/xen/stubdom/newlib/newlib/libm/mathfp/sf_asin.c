
/* @(#)z_asinf.c 1.0 98/08/13 */
/******************************************************************
 * Arcsine
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   arcsine of x
 *
 * Description:
 *   This routine returns the arcsine of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float
_DEFUN (asinf, (float),
        float x)
{
  return (asinef (x, 0));
}

#ifdef _DOUBLE_IS_32BITS

double asin (double x)
{
  return (double) asinef ((float) x, 0);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
