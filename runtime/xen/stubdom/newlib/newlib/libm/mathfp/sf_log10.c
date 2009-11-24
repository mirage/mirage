
/* @(#)z_log10f.c 1.0 98/08/13 */
/******************************************************************
 * Logarithm
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   logarithm of x
 *
 * Description:
 *   This routine returns the logarithm of x (base 10).
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float
_DEFUN (log10f, (float),
        float x)
{
  return (logarithmf (x, 1));
}

#ifdef _DOUBLE_IS_32BITS

double log10 (double x)
{
  return (double) log10f ((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
