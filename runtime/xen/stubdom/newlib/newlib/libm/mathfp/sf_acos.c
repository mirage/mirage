
/* @(#)z_acosf.c 1.0 98/08/13 */
/******************************************************************
 * Arccosine
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   arccosine of x
 *
 * Description:
 *   This routine returns the arccosine of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float
_DEFUN (acosf, (float),
        float x)
{
  return (asinef (x, 1));
}

#ifdef _DOUBLE_IS_32BITS
double acos (double x)
{
  return (double) asinef ((float) x, 1);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
