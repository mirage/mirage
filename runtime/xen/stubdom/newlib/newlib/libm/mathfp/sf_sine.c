
/* @(#)z_sinef.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/
/******************************************************************
 * sine generator
 *
 * Input:
 *   x - floating point value
 *   cosine - indicates cosine value
 *
 * Output:
 *   Sine of x.
 *
 * Description:
 *   This routine calculates sines and cosines.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

static const float HALF_PI = 1.570796326;
static const float ONE_OVER_PI = 0.318309886;
static const float r[] = { -0.1666665668,
                            0.8333025139e-02,
                           -0.1980741872e-03,
                            0.2601903036e-5 };

float
_DEFUN (sinef, (float, int),
        float x _AND
        int cosine)
{
  int sgn, N;
  float y, XN, g, R, res;
  float YMAX = 210828714.0;

  switch (numtestf (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        errno = EDOM;
        return (z_notanum_f.f); 
    }

  /* Use sin and cos properties to ease computations. */
  if (cosine)
    {
      sgn = 1;
      y = fabsf (x) + HALF_PI;
    }
  else
    {
      if (x < 0.0)
        {
          sgn = -1;
          y = -x;
        }
      else
        {
          sgn = 1;
          y = x;
        }
    }

  /* Check for values of y that will overflow here. */
  if (y > YMAX)
    {
      errno = ERANGE;
      return (x);
    }

  /* Calculate the exponent. */
  if (y < 0.0)
    N = (int) (y * ONE_OVER_PI - 0.5);
  else
    N = (int) (y * ONE_OVER_PI + 0.5);
  XN = (float) N;

  if (N & 1)
    sgn = -sgn;

  if (cosine)
    XN -= 0.5;

  y = fabsf (x) - XN * __PI;

  if (-z_rooteps_f < y && y < z_rooteps_f)
    res = y;

  else
    {
      g = y * y;

      /* Calculate the Taylor series. */
      R = (((r[3] * g + r[2]) * g + r[1]) * g + r[0]) * g;

      /* Finally, compute the result. */
      res = y + y * R;
    }
 
  res *= sgn;

  return (res);
}
