
/* @(#)z_exp.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/

/*
FUNCTION
        <<exp>>, <<expf>>---exponential
INDEX
        exp
INDEX
        expf

ANSI_SYNOPSIS
        #include <math.h>
        double exp(double <[x]>);
        float expf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double exp(<[x]>);
        double <[x]>;

        float expf(<[x]>);
        float <[x]>;

DESCRIPTION
        <<exp>> and <<expf>> calculate the exponential of <[x]>, that is,
        @ifnottex
        e raised to the power <[x]> (where e
        @end ifnottex
        @tex
        $e^x$ (where $e$
        @end tex
        is the base of the natural system of logarithms, approximately 2.71828).

RETURNS
        On success, <<exp>> and <<expf>> return the calculated value.
        If the result underflows, the returned value is <<0>>.  If the
        result overflows, the returned value is <<HUGE_VAL>>.  In
        either case, <<errno>> is set to <<ERANGE>>.

PORTABILITY
        <<exp>> is ANSI C.  <<expf>> is an extension.

*/

/*****************************************************************
 * Exponential Function
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   e raised to x.
 *
 * Description:
 *   This routine returns e raised to the xth power.
 *
 *****************************************************************/

#include <float.h>
#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

static const double INV_LN2 = 1.4426950408889634074;
static const double LN2 = 0.6931471805599453094172321;
static const double p[] = { 0.25, 0.75753180159422776666e-2,
                     0.31555192765684646356e-4 };
static const double q[] = { 0.5, 0.56817302698551221787e-1,
                     0.63121894374398504557e-3,
                     0.75104028399870046114e-6 };

double
_DEFUN (exp, (double),
        double x)
{
  int N;
  double g, z, R, P, Q;

  switch (numtest (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        errno = ERANGE;
        if (ispos (x))
          return (z_infinity.d);
        else
          return (0.0);
      case 0:
        return (1.0);
    }

  /* Check for out of bounds. */
  if (x > BIGX || x < SMALLX)
    {
      errno = ERANGE;
      return (x);
    }

  /* Check for a value too small to calculate. */
  if (-z_rooteps < x && x < z_rooteps)
    {
      return (1.0);
    }

  /* Calculate the exponent. */
  if (x < 0.0)
    N = (int) (x * INV_LN2 - 0.5);
  else
    N = (int) (x * INV_LN2 + 0.5);

  /* Construct the mantissa. */
  g = x - N * LN2;
  z = g * g;
  P = g * ((p[2] * z + p[1]) * z + p[0]);
  Q = ((q[3] * z + q[2]) * z + q[1]) * z + q[0];
  R = 0.5 + P / (Q - P);

  /* Return the floating point value. */
  N++;
  return (ldexp (R, N));
}

#endif /* _DOUBLE_IS_32BITS */
