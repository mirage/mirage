
/* @(#)z_tan.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/

/*
FUNCTION
        <<tan>>, <<tanf>>---tangent

INDEX
tan
INDEX
tanf

ANSI_SYNOPSIS
        #include <math.h>
        double tan(double <[x]>);
        float tanf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double tan(<[x]>)
        double <[x]>;

        float tanf(<[x]>)
        float <[x]>;


DESCRIPTION
<<tan>> computes the tangent of the argument <[x]>.
Angles are specified in radians.

<<tanf>> is identical, save that it takes and returns <<float>> values.

RETURNS
The tangent of <[x]> is returned.

PORTABILITY
<<tan>> is ANSI. <<tanf>> is an extension.
*/

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

#ifndef _DOUBLE_IS_32BITS

static const double TWO_OVER_PI = 0.63661977236758134308;
static const double p[] = { -0.13338350006421960681,
                             0.34248878235890589960e-2,
                            -0.17861707342254426711e-4 };
static const double q[] = { -0.46671683339755294240,
                             0.25663832289440112864e-1,
                            -0.31181531907010027307e-3,
                             0.49819433993786512270e-6 };

double
_DEFUN (tan, (double),
        double x)
{
  double y, f, g, XN, xnum, xden, res;
  int N;

  /* Check for special values. */
  switch (numtest (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        errno = EDOM;
        return (z_notanum.d);
    }

  y = fabs (x);

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

  XN = (double) N;

  f = x - N * __PI_OVER_TWO;

  /* Check for values that are too small. */
  if (-z_rooteps < f && f < z_rooteps)
    {
      xnum = f;
      xden = 1.0;
    }

  /* Calculate the polynomial. */ 
  else
    { 
      g = f * f;

      xnum = f * ((p[2] * g + p[1]) * g + p[0]) * g + f;
      xden = (((q[3] * g + q[2]) * g + q[1]) * g + q[0]) * g + 1.0;
    }

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

#endif /* _DOUBLE_IS_32BITS */
