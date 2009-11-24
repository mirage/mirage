
/* @(#)z_sinf.c 1.0 98/08/13 */
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

float
_DEFUN (sinf, (float),
        float x)
{
  return (sinef (x, 0));
}

#ifdef _DOUBLE_IS_32BITS

double sin (double x)
{
  return (double) sinef ((float) x, 0);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
