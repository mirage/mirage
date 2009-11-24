
/* @(#)z_ceil.c 1.0 98/08/13 */
/*****************************************************************
 * ceil
 *
 * Input:
 *   x  - floating point value
 *
 * Output:
 *   Smallest integer greater than x.
 *
 * Description:
 *   This routine returns the smallest integer greater than x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (ceil, (double),
        double x)
{
  double f, y;

  y = modf (x, &f);

  if (y == 0.0)
    return (x);
  else if (x > -1.0 && x < 1.0)
    return (x > 0 ? 1.0 : 0.0);
  else
    return (x > 0 ? f + 1.0 : f);
}

#endif /* _DOUBLE_IS_32BITS */
