
/* @(#)z_atan.c 1.0 98/08/13 */

/*
FUNCTION
        <<atan>>, <<atanf>>---arc tangent

INDEX
   atan
INDEX
   atanf

ANSI_SYNOPSIS
        #include <math.h>
        double atan(double <[x]>);
        float atanf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double atan(<[x]>);
        double <[x]>;

        float atanf(<[x]>);
        float <[x]>;

DESCRIPTION

<<atan>> computes the inverse tangent (arc tangent) of the input value.

<<atanf>> is identical to <<atan>>, save that it operates on <<floats>>.

RETURNS
@ifnottex
<<atan>> returns a value in radians, in the range of -pi/2 to pi/2.
@end ifnottex
@tex
<<atan>> returns a value in radians, in the range of $-\pi/2$ to $\pi/2$.
@end tex

PORTABILITY
<<atan>> is ANSI C.  <<atanf>> is an extension.

*/

/******************************************************************
 * Arctangent
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   arctan of x
 *
 * Description:
 *   This routine returns the arctan of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (atan, (double),
        double x)
{
  switch (numtest (x))
    {
      case NAN:
        errno = EDOM;
        return (x);
      case INF:
        /* this should check to see if neg NaN or pos NaN... */
        return (__PI_OVER_TWO);
      case 0:
        return (0.0);
      default:
        return (atangent (x, 0, 0, 0));
    }
}

#endif /* _DOUBLE_IS_32BITS */
