
/* @(#)z_tanf.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/
/******************************************************************
 * Tangent
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   tangent of x
 *
 * Description:
 *   This routine calculates the tangent of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

static const float TWO_OVER_PI = 0.6366197723;
static const float p[] = { -0.958017723e-1 };
static const float q[] = { -0.429135777,
                            0.971685835e-2 };

float
_DEFUN (tanf, (float),
        float x)
{
  float y, f, g, XN, xnum, xden, res;
  int N;

  /* Check for special values. */
  switch (numtestf (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        errno = EDOM;
        return (z_notanum_f.f);
    }

  y = fabsf (x);

  /* Check for values that are out of our range. */
  if (y > 105414357.0)
    {
      errno = ERANGE;
      return (y);
    }

  if (x < 0.0)
    N = (int) (x * TWO_OVER_PI - 0.5);
  else
    N = (int) (x * TWO_OVER_PI + 0.5);

  XN = (float) N;

  f = x - N * __PI_OVER_TWO;

  /* Check for values that are too small. */
  if (-z_rooteps_f < f && f < z_rooteps_f)
    {
      xnum = f;
      xden = 1.0;
    }

  /* Calculate the polynomial. */ 
  else
    { 
      g = f * f;

      xnum = f * (p[0] * g) + f;
      xden = (q[1] * g + q[0]) * g + 1.0;
    }

  /* Check for odd or even values. */
  if (N & 1)
    {
      xnum = -xnum;
      res = xden / xnum;
    } 
  else
    {
      res = xnum / xden;
    }

  return (res);
}

#ifdef _DOUBLE_IS_32BITS

double tan (double x)
{
  return (double) tanf ((float) x);
}

#endif /* _DOUBLE_IS_32BITS */
