
/* @(#)z_cosh.c 1.0 98/08/13 */

/*

FUNCTION
        <<cosh>>, <<coshf>>---hyperbolic cosine

ANSI_SYNOPSIS
        #include <math.h>
        double cosh(double <[x]>);
        float coshf(float <[x]>)

TRAD_SYNOPSIS
        #include <math.h>
        double cosh(<[x]>)
        double <[x]>;

        float coshf(<[x]>)
        float <[x]>;

DESCRIPTION

        <<cosh>> computes the hyperbolic cosine of the argument <[x]>.
        <<cosh(<[x]>)>> is defined as
        @ifnottex
        . (exp(x) + exp(-x))/2
        @end ifnottex
        @tex
        $${(e^x + e^{-x})} \over 2$$
        @end tex

        Angles are specified in radians.

        <<coshf>> is identical, save that it takes and returns <<float>>.

RETURNS
        The computed value is returned.  When the correct value would create
        an overflow,  <<cosh>> returns the value <<HUGE_VAL>> with the
        appropriate sign, and the global value <<errno>> is set to <<ERANGE>>.

        You can modify error handling for these functions using the
        function <<matherr>>.

PORTABILITY
        <<cosh>> is ANSI.
        <<coshf>> is an extension.

QUICKREF
        cosh ansi pure
        coshf - pure
*/

/******************************************************************
 * Hyperbolic Cosine
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   hyperbolic cosine of x
 *
 * Description:
 *   This routine returns the hyperbolic cosine of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (cosh, (double),
        double x)
{
  return (sineh (x, 1));
}

#endif /* _DOUBLE_IS_32BITS */
