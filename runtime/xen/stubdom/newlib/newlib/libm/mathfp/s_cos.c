
/* @(#)z_cos.c 1.0 98/08/13 */
/******************************************************************
 * Cosine
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   cosine of x
 *
 * Description:
 *   This routine returns the cosine of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (cos, (double),
        double x)
{
  return (sine (x, 1));
}

#endif /* _DOUBLE_IS_32BITS */
