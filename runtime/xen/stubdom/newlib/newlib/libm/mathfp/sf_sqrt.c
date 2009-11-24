
/* @(#)z_sqrtf.c 1.0 98/08/13 */
/*****************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 *****************************************************************/
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

float
_DEFUN (sqrtf, (float),
        float x)
{
  float f, y;
  int exp, i, odd;

  /* Check for special values. */
  switch (numtestf (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        if (isposf (x))
          {
            errno = EDOM;
            return (z_notanum_f.f);
          }
        else
          {
            errno = ERANGE;
            return (z_infinity_f.f);
          }
    } 

  /* Initial checks are performed here. */
  if (x == 0.0)
    return (0.0);
  if (x < 0)
    {
      errno = EDOM;
      return (z_notanum_f.f);
    }

  /* Find the exponent and mantissa for the form x = f * 2^exp. */
  f = frexpf (x, &exp);
  odd = exp & 1;

  /* Get the initial approximation. */
  y = 0.41731 + 0.59016 * f;

  f *= 0.5;
  /* Calculate the remaining iterations. */
  for (i = 0; i < 2; ++i)
    y = y * 0.5 + f / y;

  /* Calculate the final value. */
  if (odd)
    {
      y *= __SQRT_HALF;
      exp++;
    }
  exp >>= 1;
  y = ldexpf (y, exp);

  return (y);
}

#ifdef _DOUBLE_IS_32BITS

double sqrt (double x)
{
  return (double) sqrtf ((float) x);
}

#endif /* _DOUBLE_IS_32BITS */
