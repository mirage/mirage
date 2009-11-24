
/* @(#)z_sinehf.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/
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

static const float q[] = { -0.428277109e+2 };
static const float p[] = { -0.713793159e+1,
                           -0.190333399 };
static const float LNV = 0.6931610107;
static const float INV_V2 = 0.2499930850;
static const float V_OVER2_MINUS1 = 0.1383027787e-4;

float
_DEFUN (sinehf, (float, int),
        float x _AND
        int cosineh)
{
  float y, f, P, Q, R, res, z, w;
  int sgn = 1;
  float WBAR = 18.55;

  /* Check for special values. */
  switch (numtestf (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        errno = ERANGE;
        return (ispos (x) ? z_infinity_f.f : -z_infinity_f.f);
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
      if (y < z_rooteps_f)
        {
          res = x;
        }
      /* Calculate the Taylor series. */
      else
        { 
          f = x * x;
          Q = f + q[0];
          P = p[1] * f + p[0];
          R = f * (P / Q); 

          res = x + x * R;
        }
    }

  return (res);
}
