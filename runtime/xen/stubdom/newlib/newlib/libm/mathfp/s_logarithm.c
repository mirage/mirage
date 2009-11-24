
/* @(#)z_logarithm.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/

/*
FUNCTION
       <<log>>, <<logf>>, <<log10>>, <<log10f>>, <<logarithm>>, <<logarithmf>>---natural or base 10 logarithms

INDEX
    log
INDEX
    logf
INDEX
    log10
INDEX
    log10f

ANSI_SYNOPSIS
       #include <math.h>
       double log(double <[x]>);
       float logf(float <[x]>);
       double log10(double <[x]>);
       float log10f(float <[x]>);

TRAD_SYNOPSIS
       #include <math.h>
       double log(<[x]>);
       double <[x]>;

       float logf(<[x]>);
       float <[x]>;

       double log10(<[x]>);
       double <[x]>;

       float log10f(<[x]>);
       float <[x]>;

DESCRIPTION
Return the natural or base 10 logarithm of <[x]>, that is, its logarithm base e
(where e is the base of the natural system of logarithms, 2.71828@dots{}) or
base 10.
<<log>> and <<logf>> are identical save for the return and argument types.
<<log10>> and <<log10f>> are identical save for the return and argument types.

RETURNS
Normally, returns the calculated value.  When <[x]> is zero, the
returned value is <<-HUGE_VAL>> and <<errno>> is set to <<ERANGE>>.
When <[x]> is negative, the returned value is <<-HUGE_VAL>> and
<<errno>> is set to <<EDOM>>.  You can control the error behavior via
<<matherr>>.

PORTABILITY
<<log>> is ANSI. <<logf>> is an extension.

<<log10>> is ANSI. <<log10f>> is an extension.
*/


/******************************************************************
 * Logarithm
 *
 * Input:
 *   x - floating point value
 *   ten - indicates base ten numbers
 *
 * Output:
 *   logarithm of x
 *
 * Description:
 *   This routine calculates logarithms.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

static const double a[] = { -0.64124943423745581147e+02,
                             0.16383943563021534222e+02,
                            -0.78956112887481257267 };
static const double b[] = { -0.76949932108494879777e+03,
                             0.31203222091924532844e+03,
                            -0.35667977739034646171e+02 };
static const double C1 =  22713.0 / 32768.0;
static const double C2 =  1.428606820309417232e-06;
static const double C3 =  0.43429448190325182765;

double
_DEFUN (logarithm, (double, int),
        double x _AND
        int ten)
{
  int N;
  double f, w, z;

  /* Check for range and domain errors here. */
  if (x == 0.0)
    {
      errno = ERANGE;
      return (-z_infinity.d);
    }
  else if (x < 0.0)
    {
      errno = EDOM;
      return (z_notanum.d);
    }
  else if (!isfinite(x))
    {
      if (isnan(x))
        return (z_notanum.d);
      else
        return (z_infinity.d);
    }

  /* Get the exponent and mantissa where x = f * 2^N. */
  f = frexp (x, &N);

  z = f - 0.5;

  if (f > __SQRT_HALF)
    z = (z - 0.5) / (f * 0.5 + 0.5);
  else
    {
      N--;
      z /= (z * 0.5 + 0.5);
    }
  w = z * z;

  /* Use Newton's method with 4 terms. */
  z += z * w * ((a[2] * w + a[1]) * w + a[0]) / (((w + b[2]) * w + b[1]) * w + b[0]);

  if (N != 0)
    z = (N * C2 + z) + N * C1;

  if (ten)
    z *= C3;

  return (z);
}

#endif /* _DOUBLE_IS_32BITS */
