
/* @(#)z_asinef.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/
/******************************************************************
 * Arcsine
 *
 * Input:
 *   x - floating point value
 *   acosine - indicates acos calculation
 *
 * Output:
 *   Arcsine of x.
 *
 * Description:
 *   This routine calculates arcsine / arccosine.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

static const float p[] = { 0.933935835, -0.504400557 };
static const float q[] = { 0.560363004e+1, -0.554846723e+1 };
static const float a[] = { 0.0, 0.785398163 };
static const float b[] = { 1.570796326, 0.785398163 };

float
_DEFUN (asinef, (float, int),
        float x _AND
        int acosine)
{
  int flag, i;
  int branch = 0;
  float g, res, R, P, Q, y;

  /* Check for special values. */
  i = numtestf (x);
  if (i == NAN || i == INF)
    {
      errno = EDOM;
      if (i == NAN)
        return (x);
      else
        return (z_infinity_f.f);
    }

  y = fabsf (x);
  flag = acosine;

  if (y > 0.5)
    {
      i = 1 - flag;

      /* Check for range error. */
      if (y > 1.0)
        {
          errno = ERANGE;
          return (z_notanum_f.f);
        }

      g = (1 - y) / 2.0;
      y = -2 * sqrt (g);
      branch = 1;
    }
  else
    {
      i = flag;
      if (y < z_rooteps_f)
        res = y;
      else
        g = y * y;
    }

  if (y >= z_rooteps_f || branch == 1)
    {
      /* Calculate the Taylor series. */
      P = (p[1] * g + p[0]) * g;
      Q = (g + q[1]) * g + q[0];
      R = P / Q;

      res = y + y * R;
    }

  /* Calculate asine or acose. */
  if (flag == 0)
    {
      res = (a[i] + res) + a[i];
      if (x < 0.0)
        res = -res;
    }
  else
    {
      if (x < 0.0)
        res = (b[i] + res) + b[i];
      else
        res = (a[i] - res) + a[i];
    }

  return (res);
}
