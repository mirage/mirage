
/* @(#)z_frexpf.c 1.0 98/08/13 */
/******************************************************************
 * frexp
 *
 * Input:
 *   d   - floating point value
 *   exp - exponent value
 *
 * Output:
 *   A floating point value in the range [0.5, 1).
 *
 * Description:
 *   This routine breaks a floating point value into a number f and
 *   an exponent exp such that d = f * 2 ^ exp.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

float frexpf (float d, int *exp)
{
  float f;
  __int32_t wf, wd;

  /* Check for special values. */
  switch (numtestf (d))
    {
      case NAN:
      case INF:
        errno = EDOM;
      case 0:
        *exp = 0;
        return (d);
    }

  GET_FLOAT_WORD (wd, d);

  /* Get the exponent. */
  *exp = ((wd & 0x7f800000) >> 23) - 126;

  /* Get the mantissa. */ 
  wf = wd & 0x7fffff;  
  wf |= 0x3f000000;

  SET_FLOAT_WORD (f, wf);

  return (f);
}

#ifdef _DOUBLE_IS_32BITS

double frexp (double x, int *exp)
{
  return (double) frexpf ((float) x, exp);
}

#endif /* defined(_DOUBLE_IS_32BITS) */
