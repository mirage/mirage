
/* @(#)z_sine.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/

/*
FUNCTION
        <<sin>>, <<cos>>, <<sine>>, <<sinf>>, <<cosf>>, <<sinef>>---sine or cosine
INDEX
sin
INDEX
sinf
INDEX
cos
INDEX
cosf
ANSI_SYNOPSIS
        #include <math.h>
        double sin(double <[x]>);
        float  sinf(float <[x]>);
        double cos(double <[x]>);
        float cosf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double sin(<[x]>)
        double <[x]>;
        float  sinf(<[x]>)
        float <[x]>;

        double cos(<[x]>)
        double <[x]>;
        float cosf(<[x]>)
        float <[x]>;

DESCRIPTION
        <<sin>> and <<cos>> compute (respectively) the sine and cosine
        of the argument <[x]>.  Angles are specified in radians.
RETURNS
        The sine or cosine of <[x]> is returned.

PORTABILITY
        <<sin>> and <<cos>> are ANSI C.
        <<sinf>> and <<cosf>> are extensions.

QUICKREF
        sin ansi pure
        sinf - pure
*/

/******************************************************************
 * sine
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

#ifndef _DOUBLE_IS_32BITS

static const double HALF_PI = 1.57079632679489661923;
static const double ONE_OVER_PI = 0.31830988618379067154;
static const double r[] = { -0.16666666666666665052,
                             0.83333333333331650314e-02,
                            -0.19841269841201840457e-03,
                             0.27557319210152756119e-05,
                            -0.25052106798274584544e-07,
                             0.16058936490371589114e-09,
                            -0.76429178068910467734e-12,
                             0.27204790957888846175e-14 };

double
_DEFUN (sine, (double, int),
        double x _AND
        int cosine)
{
  int sgn, N;
  double y, XN, g, R, res;
  double YMAX = 210828714.0;

  switch (numtest (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        errno = EDOM;
        return (z_notanum.d); 
    }

  /* Use sin and cos properties to ease computations. */
  if (cosine)
    {
      sgn = 1;
      y = fabs (x) + HALF_PI;
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
  XN = (double) N;

  if (N & 1)
    sgn = -sgn;

  if (cosine)
    XN -= 0.5;

  y = fabs (x) - XN * __PI;

  if (-z_rooteps < y && y < z_rooteps)
    res = y;

  else
    {
      g = y * y;

      /* Calculate the Taylor series. */
      R = (((((((r[6] * g + r[5]) * g + r[4]) * g + r[3]) * g + r[2]) * g + r[1]) * g + r[0]) * g);

      /* Finally, compute the result. */
      res = y + y * R;
    }
 
  res *= sgn;

  return (res);
}

#endif /* _DOUBLE_IS_32BITS */
