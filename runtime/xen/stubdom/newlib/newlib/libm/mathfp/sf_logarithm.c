
/* @(#)z_logarithmf.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/
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

static const float a[] = { -0.5527074855 };
static const float b[] = { -0.6632718214e+1 };
static const float C1 = 0.693145752;
static const float C2 = 1.428606820e-06;
static const float C3 = 0.4342944819;

float
_DEFUN (logarithmf, (float, int),
        float x _AND
        int ten)
{
  int N;
  float f, w, z;

  /* Check for domain/range errors here. */
  if (x == 0.0)
    {
      errno = ERANGE;
      return (-z_infinity_f.f);
    }
  else if (x < 0.0)
    {
      errno = EDOM;
      return (z_notanum_f.f);
    }
  else if (!isfinitef(x))
    {
      if (isnanf(x)) 
        return (z_notanum_f.f);
      else
        return (z_infinity_f.f);
    }

  /* Get the exponent and mantissa where x = f * 2^N. */
  f = frexpf (x, &N);

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
  z += z * w * (a[0]) / ((w + 1.0) * w + b[0]);

  if (N != 0)
    z = (N * C2 + z) + N * C1;

  if (ten)
    z *= C3;

  return (z);
}
