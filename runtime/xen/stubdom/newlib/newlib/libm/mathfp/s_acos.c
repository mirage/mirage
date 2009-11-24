
/* @(#)z_acos.c 1.0 98/08/13 */

/*
FUNCTION
        <<acos>>, <<acosf>>---arc cosine

INDEX
        acos
INDEX
        acosf

ANSI_SYNOPSIS
        #include <math.h>
        double acos(double <[x]>);
        float acosf(float <[x]>);

TRAD_SYNOPSIS
        #include <math.h>
        double acos(<[x]>)
        double <[x]>;

        float acosf(<[x]>)
        float <[x]>;



DESCRIPTION

        <<acos>> computes the inverse cosine (arc cosine) of the input value.
        Arguments to <<acos>> must be in the range @minus{}1 to 1.

        <<acosf>> is identical to <<acos>>, except that it performs
        its calculations on <<floats>>.

RETURNS
        @ifnottex
        <<acos>> and <<acosf>> return values in radians, in the range of 0 to pi
.
        @end ifnottex
        @tex
        <<acos>> and <<acosf>> return values in radians, in the range of <<0>> t
o $\pi$.
        @end tex

        If <[x]> is not between @minus{}1 and 1, the returned value is NaN
        (not a number) the global variable <<errno>> is set to <<EDOM>>, and a
        <<DOMAIN error>> message is sent as standard error output.

        You can modify error handling for these functions using <<matherr>>.


QUICKREF ANSI SVID POSIX RENTRANT
 acos    y,y,y,m
 acosf   n,n,n,m

MATHREF
 acos, [-1,1], acos(arg),,,
 acos, NAN,    arg,DOMAIN,EDOM

MATHREF
 acosf, [-1,1], acosf(arg),,,
 acosf, NAN,    argf,DOMAIN,EDOM

*/

/*****************************************************************
 * Arccosine
 *
 * Input:
 *   x - floating point value
 *
 * Output:
 *   arccosine of x
 *
 * Description:
 *   This routine returns the arccosine of x.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double
_DEFUN (acos, (double),
        double x)
{
  return (asine (x, 1));
}

#endif /* _DOUBLE_IS_32BITS */
