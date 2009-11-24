
/* @(#)z_atangentf.c 1.0 98/08/13 */
/******************************************************************
 * The following routines are coded directly from the algorithms
 * and coefficients given in "Software Manual for the Elementary
 * Functions" by William J. Cody, Jr. and William Waite, Prentice
 * Hall, 1980.
 ******************************************************************/
/******************************************************************
 * Arctangent
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   arctangent of x
 *
 * Description:
 *   This routine calculates arctangents.
 *
 *****************************************************************/

#include <float.h>
#include "fdlibm.h"
#include "zmath.h"

static const float ROOT3 = 1.732050807;
static const float a[] = { 0.0, 0.523598775, 1.570796326,
                     1.047197551 };
static const float q[] = { 0.1412500740e+1 };
static const float p[] = { -0.4708325141, -0.5090958253e-1 };

float
_DEFUN (atangentf, (float, float, float, int),
        float x _AND
        float v _AND
        float u _AND
        int arctan2)
{
  float f, g, R, P, Q, A, res;
  int N;
  int branch = 0;
  int expv, expu;

  /* Preparation for calculating arctan2. */
  if (arctan2)
    {
      if (u == 0.0)
        if (v == 0.0)
          {
            errno = ERANGE;
            return (z_notanum_f.f);
          }
        else
          {
            branch = 1;
            res = __PI_OVER_TWO;
          }

      if (!branch)
        {
          int e;
          /* Get the exponent values of the inputs. */
          g = frexpf (v, &expv);
          g = frexpf (u, &expu);

          /* See if a divide will overflow. */
          e = expv - expu;
          if (e > FLT_MAX_EXP)
            {
               branch = 1;
               res = __PI_OVER_TWO;
            }

          /* Also check for underflow. */
          else if (e < FLT_MIN_EXP)
            {
               branch = 2;
               res = 0.0;
            }
         }
    }

  if (!branch)
    {
      if (arctan2)
        f = fabsf (v / u);
      else
        f = fabsf (x);

      if (f > 1.0)
        {
          f = 1.0 / f;
          N = 2;
        }
      else
        N = 0;

      if (f > (2.0 - ROOT3))
        {
          A = ROOT3 - 1.0;
          f = (((A * f - 0.5) - 0.5) + f) / (ROOT3 + f);
          N++;
        }

      /* Check for values that are too small. */
      if (-z_rooteps_f < f && f < z_rooteps_f)
        res = f;

      /* Calculate the Taylor series. */
      else
        {
          g = f * f;
          P = (p[1] * g + p[0]) * g;
          Q = g + q[0];
          R = P / Q;

          res = f + f * R;
        }

      if (N > 1)
        res = -res;

      res += a[N];
    }

  if (arctan2)
    {
      if (u < 0.0)
        res = __PI - res;
      if (v < 0.0)
        res = -res;
    }
  else if (x < 0.0)
    {
      res = -res;
    }

  return (res);
}
