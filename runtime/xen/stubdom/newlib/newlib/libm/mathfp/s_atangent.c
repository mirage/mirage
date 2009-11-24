
/* @(#)z_atangent.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/

/*
FUNCTION
        <<atan>>, <<atanf>>, <<atan2>>, <<atan2f>>, <<atangent>>, <<atangentf>>---arc tangent

INDEX
   atan2
INDEX
   atan2f
INDEX
   atan
INDEX
   atanf

ANSI_SYNOPSIS
        #include <math.h>
        double atan(double <[x]>);
        float atan(float <[x]>);
        double atan2(double <[y]>,double <[x]>);
        float atan2f(float <[y]>,float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double atan2(<[y]>,<[x]>);
        double <[y]>;
        double <[x]>;

        float atan2f(<[y]>,<[x]>);
        float <[y]>;
        float <[x]>;

        #include <math.h>
        double atan(<[x]>);
        double <[x]>;

        float atanf(<[x]>);
        float <[x]>;

DESCRIPTION

<<atan2>> computes the inverse tangent (arc tangent) of y / x.

<<atan2f>> is identical to <<atan2>>, save that it operates on <<floats>>.

<<atan>> computes the inverse tangent (arc tangent) of the input value.

<<atanf>> is identical to <<atan>>, save that it operates on <<floats>>.

RETURNS
@ifnottex
<<atan>> returns a value in radians, in the range of -pi/2 to pi/2.
<<atan2>> returns a value in radians, in the range of -pi/2 to pi/2.
@end ifnottex
@tex
<<atan>> returns a value in radians, in the range of $-\pi/2$ to $\pi/2$.
<<atan2>> returns a value in radians, in the range of $-\pi/2$ to $\pi/2$.
@end tex

PORTABILITY
<<atan>> is ANSI C.  <<atanf>> is an extension.
<<atan2>> is ANSI C.  <<atan2f>> is an extension.

*/

/******************************************************************
 * Arctangent
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   arctangent of x
 *
 * Description:
 *   This routine calculates arctangents.
 *
 *****************************************************************/
#include <float.h>
#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

static const double ROOT3 = 1.73205080756887729353;
static const double a[] = { 0.0, 0.52359877559829887308, 1.57079632679489661923,
                     1.04719755119659774615 };
static const double q[] = { 0.41066306682575781263e+2,
                     0.86157349597130242515e+2,
                     0.59578436142597344465e+2,
                     0.15024001160028576121e+2 };
static const double p[] = { -0.13688768894191926929e+2,
                     -0.20505855195861651981e+2,
                     -0.84946240351320683534e+1,
                     -0.83758299368150059274 };

double
_DEFUN (atangent, (double, double, double, int),
        double x _AND
        double v _AND
        double u _AND
        int arctan2)
{
  double f, g, R, P, Q, A, res;
  int N;
  int branch = 0;
  int expv, expu;

  /* Preparation for calculating arctan2. */
  if (arctan2)
    {
      if (u == 0.0)
        if (v == 0.0)
          {
            errno = ERANGE;
            return (z_notanum.d);
          }
        else
          {
            branch = 1;
            res = __PI_OVER_TWO;
          }

      if (!branch)
        {
          int e;
          /* Get the exponent values of the inputs. */
          g = frexp (v, &expv);
          g = frexp (u, &expu);

          /* See if a divide will overflow. */
          e = expv - expu;
          if (e > DBL_MAX_EXP)
            {
               branch = 1;
               res = __PI_OVER_TWO;
            }

          /* Also check for underflow. */
          else if (e < DBL_MIN_EXP)
            {
               branch = 2;
               res = 0.0;
            }
         }
    }

  if (!branch)
    {
      if (arctan2)
        f = fabs (v / u);
      else
        f = fabs (x);

      if (f > 1.0)
        {
          f = 1.0 / f;
          N = 2;
        }
      else
        N = 0;

      if (f > (2.0 - ROOT3))
        {
          A = ROOT3 - 1.0;
          f = (((A * f - 0.5) - 0.5) + f) / (ROOT3 + f);
          N++;
        }

      /* Check for values that are too small. */
      if (-z_rooteps < f && f < z_rooteps)
        res = f;

      /* Calculate the Taylor series. */
      else
        {
          g = f * f;
          P = (((p[3] * g + p[2]) * g + p[1]) * g + p[0]) * g;
          Q = (((g + q[3]) * g + q[2]) * g + q[1]) * g + q[0];
          R = P / Q;

          res = f + f * R;
        }

      if (N > 1)
        res = -res;

      res += a[N];
    }

  if (arctan2)
    {
      if (u < 0.0)
        res = __PI - res;
      if (v < 0.0)
        res = -res;
    }
  else if (x < 0.0)
    {
      res = -res;
    }

  return (res);
}

#endif /* _DOUBLE_IS_32BITS */
