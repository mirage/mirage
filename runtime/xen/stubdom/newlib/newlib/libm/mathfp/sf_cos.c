
/* @(#)z_cosf.c 1.0 98/08/13 */
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

float
_DEFUN (cosf, (float),
        float x)
{
  return (sinef (x, 1));
}

#ifdef _DOUBLE_IS_32BITS

double cos (double x)
{
  return (double) sinef ((float) x, 1);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
