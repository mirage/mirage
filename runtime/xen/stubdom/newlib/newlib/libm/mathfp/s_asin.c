
/* @(#)z_asin.c 1.0 98/08/13 */
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

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (asin, (double),
        double x)
{
  return (asine (x, 0));
}

#endif /* _DOUBLE_IS_32BITS */
