
/* @(#)z_log.c 1.0 98/08/13 */
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

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (log, (double),
        double x)
{
  return (logarithm (x, 0));
}

#endif /* _DOUBLE_IS_32BITS */
