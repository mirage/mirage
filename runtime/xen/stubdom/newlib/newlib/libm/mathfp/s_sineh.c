
/* @(#)z_sineh.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/

/*
FUNCTION
        <<sinh>>, <<sinhf>>, <<cosh>>, <<coshf>>, <<sineh>>---hyperbolic sine or cosine

INDEX
        sinh
INDEX
        sinhf
INDEX
        cosh
INDEX
        coshf

ANSI_SYNOPSIS
        #include <math.h>
        double sinh(double <[x]>);
        float  sinhf(float <[x]>);
        double cosh(double <[x]>);
        float  coshf(float <[x]>);
TRAD_SYNOPSIS
        #include <math.h>
        double sinh(<[x]>)
        double <[x]>;

        float  sinhf(<[x]>)
        float <[x]>;

        double cosh(<[x]>)
        double <[x]>;

        float  coshf(<[x]>)
        float <[x]>;

DESCRIPTION
        <<sinh>> and <<cosh>> compute the hyperbolic sine or cosine
        of the argument <[x]>.
        Angles are specified in radians.   <<sinh>>(<[x]>) is defined as
        @ifnottex
        . (exp(<[x]>) - exp(-<[x]>))/2
        @end ifnottex
        @tex
        $${e^x - e^{-x}}\over 2$$
        @end tex
        <<cosh>> is defined as
        @ifnottex
        . (exp(<[x]>) - exp(-<[x]>))/2
        @end ifnottex
        @tex
        $${e^x + e^{-x}}\over 2$$
        @end tex

        <<sinhf>> and <<coshf>> are identical, save that they take 
        and returns <<float>> values.

RETURNS
        The hyperbolic sine or cosine of <[x]> is returned.

        When the correct result is too large to be representable (an
        overflow),  the functions return <<HUGE_VAL>> with the
        appropriate sign, and sets the global value <<errno>> to
        <<ERANGE>>.

PORTABILITY
        <<sinh>> is ANSI C.
        <<sinhf>> is an extension.
        <<cosh>> is ANSI C.
        <<coshf>> is an extension.

*/

/******************************************************************
 * Hyperbolic Sine 
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   hyperbolic sine of x
 *
 * Description:
 *   This routine calculates hyperbolic sines.
 *
 *****************************************************************/

#include <float.h>
#include "fdlibm.h"
#include "zmath.h"

static const double q[] = { -0.21108770058106271242e+7,
                             0.36162723109421836460e+5,
                            -0.27773523119650701667e+3 };
static const double p[] = { -0.35181283430177117881e+6,
                            -0.11563521196851768270e+5,
                            -0.16375798202630751372e+3,
                            -0.78966127417357099479 };
static const double LNV = 0.6931610107421875000;
static const double INV_V2 = 0.24999308500451499336;
static const double V_OVER2_MINUS1 = 0.13830277879601902638e-4;

double
_DEFUN (sineh, (double, int),
        double x _AND
        int cosineh)
{
  double y, f, P, Q, R, res, z, w;
  int sgn = 1;
  double WBAR = 18.55;

  /* Check for special values. */
  switch (numtest (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        errno = ERANGE;
        return (ispos (x) ? z_infinity.d : -z_infinity.d);
    }

  y = fabs (x);

  if (!cosineh && x < 0.0)
    sgn = -1;

  if ((y > 1.0 && !cosineh) || cosineh)
    {
      if (y > BIGX)
        {
          w = y - LNV;
          
          /* Check for w > maximum here. */
          if (w > BIGX)
            {
              errno = ERANGE;
              return (x);
            }

          z = exp (w);

          if (w > WBAR)
            res = z * (V_OVER2_MINUS1 + 1.0);
        }

      else
        {
          z = exp (y);
          if (cosineh)
            res = (z + 1 / z) / 2.0;
          else
            res = (z - 1 / z) / 2.0;
        }

      if (sgn < 0)
        res = -res;
    }
  else
    {
      /* Check for y being too small. */
      if (y < z_rooteps)
        {
          res = x;
        }
      /* Calculate the Taylor series. */
      else
        { 
          f = x * x;
          Q = ((f + q[2]) * f + q[1]) * f + q[0];
          P = ((p[3] * f + p[2]) * f + p[1]) * f + p[0];
          R = f * (P / Q); 

          res = x + x * R;
        }
    }

  return (res);
}
