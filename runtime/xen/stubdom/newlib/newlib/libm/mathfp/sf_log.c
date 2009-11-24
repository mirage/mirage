
/* @(#)z_logf.c 1.0 98/08/13 */
/******************************************************************
 * Logarithm
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   natural logarithm of x
 *
 * Description:
 *   This routine returns the natural logarithm of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float
_DEFUN (logf, (float),
        float x)
{
  return (logarithmf (x, 0));
}

#ifdef _DOUBLE_IS_32BITS

double log (double x)
{
  return (double) logf ((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
