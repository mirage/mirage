
/* @(#)z_sqrt.c 1.0 98/08/13 */
/*****************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 *****************************************************************/

/*
FUNCTION
        <<sqrt>>, <<sqrtf>>---positive square root

INDEX
        sqrt
INDEX
        sqrtf

ANSI_SYNOPSIS
        #include <math.h>
        double sqrt(double <[x]>);
        float  sqrtf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double sqrt(<[x]>);
        float  sqrtf(<[x]>);

DESCRIPTION
        <<sqrt>> computes the positive square root of the argument.

RETURNS
        On success, the square root is returned. If <[x]> is real and
        positive, then the result is positive.  If <[x]> is real and
        negative, the global value <<errno>> is set to <<EDOM>> (domain error).


PORTABILITY
        <<sqrt>> is ANSI C.  <<sqrtf>> is an extension.
*/

/******************************************************************
 * Square Root
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   square-root of x
 *
 * Description:
 *   This routine performs floating point square root.
 *
 *   The initial approximation is computed as
 *     y0 = 0.41731 + 0.59016 * f
 *   where f is a fraction such that x = f * 2^exp.
 *
 *   Three Newton iterations in the form of Heron's formula
 *   are then performed to obtain the final value:
 *     y[i] = (y[i-1] + f / y[i-1]) / 2, i = 1, 2, 3.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (sqrt, (double),
        double x)
{
  double f, y;
  int exp, i, odd;

  /* Check for special values. */
  switch (numtest (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        if (ispos (x))
          {
            errno = EDOM;
            return (z_notanum.d);
          }
        else
          {
            errno = ERANGE;
            return (z_infinity.d);
          }
    }

  /* Initial checks are performed here. */
  if (x == 0.0)
    return (0.0);
  if (x < 0)
    {
      errno = EDOM;
      return (z_notanum.d);
    }

  /* Find the exponent and mantissa for the form x = f * 2^exp. */
  f = frexp (x, &exp);

  odd = exp & 1;

  /* Get the initial approximation. */
  y = 0.41731 + 0.59016 * f;

  f /= 2.0;
  /* Calculate the remaining iterations. */
  for (i = 0; i < 3; ++i)
    y = y / 2.0 + f / y;

  /* Calculate the final value. */
  if (odd)
    {
      y *= __SQRT_HALF;
      exp++;
    }
  exp >>= 1;
  y = ldexp (y, exp);

  return (y);
}

#endif /* _DOUBLE_IS_32BITS */
