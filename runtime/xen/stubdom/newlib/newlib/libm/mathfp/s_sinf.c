
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
  return (double) sinf ((float) x);
}

#endif /* _DOUBLE_IS_32BITS */
