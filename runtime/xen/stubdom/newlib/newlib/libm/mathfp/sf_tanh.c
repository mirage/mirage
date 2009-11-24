
/* @(#)z_tanhf.c 1.0 98/08/13 */
/*****************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 *****************************************************************/
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

static const float LN3_OVER2 = 0.5493061443;
static const float p[] = { -0.2059432032,
                           -0.0009577527 };
static const float q[] = {  0.6178299136,
                            0.25 };

float
_DEFUN (tanhf, (float),
        float x)
{
  float f, res, g, P, Q, R;

  f = fabsf (x);

  /* Check if the input is too big. */ 
  if (f > BIGX)
    res = 1.0; 

  else if (f > LN3_OVER2)
    res = 1.0 - 2.0 / (exp (2 * f) + 1.0);

  /* Check if the input is too small. */
  else if (f < z_rooteps_f)
    res = f;

  /* Calculate the Taylor series. */
  else
    {
      g = f * f;

      P = p[1] * g + p[0];
      Q = (g + q[1]) * g + q[0];
      R = g * (P / Q);

      res = f + f * R;
    }

  if (x < 0.0)
    res = -res;

  return (res);
}

#ifdef _DOUBLE_IS_32BITS

double tanh (double x)
{
  return (double) tanhf ((float) x);
}

#endif _DOUBLE_IS_32BITS
