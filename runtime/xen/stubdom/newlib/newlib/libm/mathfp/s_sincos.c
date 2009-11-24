
/* @(#)z_sin.c 1.0 98/08/13 */
/******************************************************************
 * Sine
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   sine of x
 *
 * Description:
 *   This routine returns the sine of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

void
_DEFUN (sincos, (x, sinx, cosx),
        double x _AND
        double *sinx _AND
        double *cosx)
{
  *sinx = sin (x);
  *cosx = cos (x);
}

#endif /* _DOUBLE_IS_32BITS */
