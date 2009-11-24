
/* @(#)z_numtest.c 1.0 98/08/13 */
/******************************************************************
 * Numtest
 *
 * Input:
 *   x - pointer to a floating point value
 *
 * Output:
 *   An integer that indicates what kind of number was passed in:
 *     NUM = 3 - a finite value
 *     NAN = 2 - not a number
 *     INF = 1 - an infinite value
 *           0 - zero
 *
 * Description:
 *   This routine returns an integer that indicates the character-
 *   istics of the number that was passed in. 
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

int 
_DEFUN (numtest, (double),
        double x)
{
  __uint32_t hx, lx;
  int exp;

  EXTRACT_WORDS (hx, lx, x);

  exp = (hx & 0x7ff00000) >> 20;

  /* Check for a zero input. */
  if (x == 0.0)
    {
      return (0);
    }

  /* Check for not a number or infinity. */
  if (exp == 0x7ff)
    {
      if(hx & 0xf0000 || lx)
        return (NAN);
      else
        return (INF);
    }
     
  /* Otherwise it's a finite value. */ 
  else
    return (NUM);
}

#endif /* _DOUBLE_IS_32BITS */
