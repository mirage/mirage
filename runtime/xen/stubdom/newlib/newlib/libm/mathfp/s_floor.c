
/* @(#)z_floor.c 1.0 98/08/13 */

/*
FUNCTION
<<floor>>, <<floorf>>, <<ceil>>, <<ceilf>>---floor and ceiling
INDEX
        floor
INDEX
        floorf
INDEX
        ceil
INDEX
        ceilf

ANSI_SYNOPSIS
        #include <math.h>
        double floor(double <[x]>);
        float floorf(float <[x]>);
        double ceil(double <[x]>);
        float ceilf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double floor(<[x]>)
        double <[x]>;
        float floorf(<[x]>)
        float <[x]>;
        double ceil(<[x]>)
        double <[x]>;
        float ceilf(<[x]>)
        float <[x]>;

DESCRIPTION
<<floor>> and <<floorf>> find
@tex
$\lfloor x \rfloor$,
@end tex
the nearest integer less than or equal to <[x]>.
<<ceil>> and <<ceilf>> find
@tex
$\lceil x\rceil$,
@end tex
the nearest integer greater than or equal to <[x]>.

RETURNS
<<floor>> and <<ceil>> return the integer result as a double.
<<floorf>> and <<ceilf>> return the integer result as a float.

PORTABILITY
<<floor>> and <<ceil>> are ANSI.
<<floorf>> and <<ceilf>> are extensions.

*/

/*****************************************************************
 * floor 
 *
 * Input:
 *   x  - floating point value
 *
 * Output:
 *   Smallest integer less than x.
 *
 * Description:
 *   This routine returns the smallest integer less than x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double 
_DEFUN (floor, (double),
              double x)
{
  double f, y;

  if (x > -1.0 && x < 1.0)
    return (x >= 0 ? 0 : -1.0);

  y = modf (x, &f);

  if (y == 0.0)
    return (x);

  return (x >= 0 ? f : f - 1.0);
}

#endif /* _DOUBLE_IS_32BITS */
