
/* @(#)z_atan2f.c 1.0 98/08/13 */
/******************************************************************
 * Arctangent2
 *
 * Input:
 *   v, u - floating point values
 *
 * Output:
 *   arctan2 of v / u 
 *
 * Description:
 *   This routine returns the arctan2 of v / u.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float
_DEFUN (atan2f, (float, float),
        float v _AND
        float u)
{
  return (atangentf (0.0, v, u, 1));
}

#ifdef _DOUBLE_IS_32BITS
double atan2 (double v, double u)
{
  return (double) atangentf (0.0, (float) v, (float) u, 1);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
