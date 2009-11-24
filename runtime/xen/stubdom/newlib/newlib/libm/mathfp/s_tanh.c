
/* @(#)z_tanh.c 1.0 98/08/13 */
/*****************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 *****************************************************************/

/*

FUNCTION
        <<tanh>>, <<tanhf>>---hyperbolic tangent

INDEX
tanh
INDEX
tanhf

ANSI_SYNOPSIS
        #include <math.h>
        double tanh(double <[x]>);
        float tanhf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double tanh(<[x]>)
        double <[x]>;

        float tanhf(<[x]>)
        float <[x]>;


DESCRIPTION

<<tanh>> computes the hyperbolic tangent of
the argument <[x]>.  Angles are specified in radians.

<<tanh(<[x]>)>> is defined as
. sinh(<[x]>)/cosh(<[x]>)

<<tanhf>> is identical, save that it takes and returns <<float>> values.

RETURNS
The hyperbolic tangent of <[x]> is returned.

PORTABILITY
<<tanh>> is ANSI C.  <<tanhf>> is an extension.

*/

/******************************************************************
 * Hyperbolic Tangent
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   hyperbolic tangent of x
 *
 * Description:
 *   This routine calculates hyperbolic tangent.
 *
 *****************************************************************/

#include <float.h>
#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

static const double LN3_OVER2 = 0.54930614433405484570;
static const double p[] = { -0.16134119023996228053e+4,
                            -0.99225929672236083313e+2,
                            -0.96437492777225469787 };
static const double q[] = { 0.48402357071988688686e+4,
                            0.22337720718962312926e+4,
                            0.11274474380534949335e+3 }; 

double
_DEFUN (tanh, (double),
        double x)
{
  double f, res, g, P, Q, R;

  f = fabs (x);

  /* Check if the input is too big. */ 
  if (f > BIGX)
    res = 1.0; 

  else if (f > LN3_OVER2)
    res = 1.0 - 2.0 / (exp (2 * f) + 1.0);

  /* Check if the input is too small. */
  else if (f < z_rooteps)
    res = f;

  /* Calculate the Taylor series. */
  else
    {
      g = f * f;

      P = (p[2] * g + p[1]) * g + p[0];
      Q = ((g + q[2]) * g + q[1]) * g + q[0];
      R = g * (P / Q);

      res = f + f * R;
    }

  if (x < 0.0)
    res = -res;

  return (res);
}

#endif /* _DOUBLE_IS_32BITS */
