
/* @(#)z_sinh.c 1.0 98/08/13 */
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

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (sinh, (double),
        double x)
{
  return (sineh (x, 0));
}

#endif /* _DOUBLE_IS_32BITS */
