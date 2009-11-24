
/* @(#)z_ispos.c 1.0 98/08/13 */
/******************************************************************
 * Numtest
 *
 * Input:
 *   x - pointer to a floating point value
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

#ifndef _DOUBLE_IS_32BITS

int ispos (double x)
{
  __uint32_t hx;

  GET_HIGH_WORD (hx, x);

  if (hx & 0x80000000)
    return (0);
  else
    return (1);
}

#endif /* _DOUBLE_IS_32BITS */
