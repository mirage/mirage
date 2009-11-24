
/* @(#)z_isposf.c 1.0 98/08/13 */
/******************************************************************
 * Positive value test
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   An integer that indicates if the number is positive.
 *
 * Description:
 *   This routine returns an integer that indicates if the number
 *   passed in is positive (1) or negative (0).
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

int isposf (float x)
{
  __int32_t wx;

  GET_FLOAT_WORD (wx, x);

  if (wx & 0x80000000)
    return (0);
  else
    return (1);
}

#ifdef _DOUBLE_IS_32BITS

int ispos (double x)
{
  return isposf ((float) x);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
