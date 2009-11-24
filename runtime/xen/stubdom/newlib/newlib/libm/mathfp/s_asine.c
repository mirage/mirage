
/* @(#)z_asine.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/

/*
FUNCTION
        <<asin>>, <<asinf>>, <<acos>>, <<acosf>>, <<asine>>, <<asinef>>---arc sine or cosine

INDEX
   asin
INDEX
   asinf
INDEX
   acos
INDEX
   acosf
INDEX
   asine
INDEX
   asinef

ANSI_SYNOPSIS
        #include <math.h>
        double asine(double <[x]>);
        float asinef(float <[x]>);
        double asin(double <[x]>);
        float asinf(float <[x]>);
        double acos(double <[x]>);
        float acosf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double asine(<[x]>);
        double <[x]>;

        float asinef(<[x]>);
        float <[x]>;

        double asin(<[x]>)
        double <[x]>;

        float asinf(<[x]>)
        float <[x]>;

        double acos(<[x]>)
        double <[x]>;

        float acosf(<[x]>)
        float <[x]>;

DESCRIPTION

<<asin>> computes the inverse sine or cosine of the argument <[x]>.
Arguments to <<asin>> and <<acos>> must be in the range @minus{}1 to 1.

<<asinf>> and <<acosf>> are identical to <<asin>> and <<acos>>, other 
than taking and returning floats.

RETURNS
@ifnottex
<<asin>> and <<acos>> return values in radians, in the range of -pi/2 to pi/2.
@end ifnottex
@tex
<<asin>> and <<acos>> return values in radians, in the range of $-\pi/2$ to $\pi/2$.
@end tex

If <[x]> is not in the range @minus{}1 to 1, <<asin>> and <<asinf>>
return NaN (not a number), set the global variable <<errno>> to
<<EDOM>>, and issue a <<DOMAIN error>> message.

*/

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

#ifndef _DOUBLE_IS_32BITS

static const double p[] = { -0.27368494524164255994e+2,
                             0.57208227877891731407e+2,
                            -0.39688862997404877339e+2,
                             0.10152522233806463645e+2,
                            -0.69674573447350646411 };
static const double q[] = { -0.16421096714498560795e+3,
                             0.41714430248260412556e+3,
                            -0.38186303361750149284e+3,
                             0.15095270841030604719e+3,
                            -0.23823859153670238830e+2 };
static const double a[] = { 0.0, 0.78539816339744830962 };
static const double b[] = { 1.57079632679489661923, 0.78539816339744830962 };

double
_DEFUN (asine, (double, int),
        double x _AND
        int acosine)
{
  int flag, i;
  int branch = 0;
  double g, res, R, P, Q, y;

  /* Check for special values. */
  i = numtest (x);
  if (i == NAN || i == INF)
    {
      errno = EDOM;
      if (i == NAN)
        return (x);
      else
        return (z_infinity.d);
    }

  y = fabs (x);
  flag = acosine;

  if (y > 0.5)
    {
      i = 1 - flag;

      /* Check for range error. */
      if (y > 1.0)
        {
          errno = ERANGE;
          return (z_notanum.d);
        }

      g = (1 - y) / 2.0;
      y = -2 * sqrt (g);
      branch = 1;
    }
  else
    {
      i = flag;
      if (y < z_rooteps)
        res = y;
      else
        g = y * y;
    }

  if (y >= z_rooteps || branch == 1)
    {
      /* Calculate the Taylor series. */
      P = ((((p[4] * g + p[3]) * g + p[2]) * g + p[1]) * g + p[0]) * g;
      Q = ((((g + q[4]) * g + q[3]) * g + q[2]) * g + q[1]) * g + q[0];
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

#endif /* _DOUBLE_IS_32BITS */
