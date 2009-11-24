
/* @(#)z_frexp.c 1.0 98/08/13 */

/*
FUNCTION
       <<frexp>>, <<frexpf>>---split floating-point number
INDEX
        frexp
INDEX
        frexpf

ANSI_SYNOPSIS
        #include <math.h>
        double frexp(double <[val]>, int *<[exp]>);
        float frexpf(float <[val]>, int *<[exp]>);

TRAD_SYNOPSIS
        #include <math.h>
        double frexp(<[val]>, <[exp]>)
        double <[val]>;
        int *<[exp]>;

        float frexpf(<[val]>, <[exp]>)
        float <[val]>;
        int *<[exp]>;


DESCRIPTION
        All nonzero, normal numbers can be described as <[m]> * 2**<[p]>.
        <<frexp>> represents the double <[val]> as a mantissa <[m]>
        and a power of two <[p]>. The resulting mantissa will always
        be greater than or equal to <<0.5>>, and less than <<1.0>> (as
        long as <[val]> is nonzero). The power of two will be stored
        in <<*>><[exp]>.

@ifnottex
<[m]> and <[p]> are calculated so that
<[val]> is <[m]> times <<2>> to the power <[p]>.
@end ifnottex
@tex
<[m]> and <[p]> are calculated so that
$ val = m \times 2^p $.
@end tex

<<frexpf>> is identical, other than taking and returning
floats rather than doubles.

RETURNS
<<frexp>> returns the mantissa <[m]>. If <[val]> is <<0>>, infinity,
or Nan, <<frexp>> will set <<*>><[exp]> to <<0>> and return <[val]>.

PORTABILITY
<<frexp>> is ANSI.
<<frexpf>> is an extension.


*/

/*****************************************************************
 * frexp
 *
 * Input:
 *   d   - floating point value
 *   exp - exponent value
 *
 * Output:
 *   A floating point value in the range [0.5, 1).
 *
 * Description:
 *   This routine breaks a floating point value into a number f and
 *   an exponent exp such that d = f * 2 ^ exp.
 *
 *****************************************************************/

#include "fdlibm.h"
#include "zmath.h"

#ifndef _DOUBLE_IS_32BITS

double frexp (double d, int *exp)
{
  double f;
  __uint32_t hd, ld, hf, lf;

  /* Check for special values. */
  switch (numtest (d))
    {
      case NAN:
      case INF:
        errno = EDOM;
      case 0:
        *exp = 0;
        return (d);
    }

  EXTRACT_WORDS (hd, ld, d);

  /* Get the exponent. */
  *exp = ((hd & 0x7ff00000) >> 20) - 1022;

  /* Get the mantissa. */ 
  lf = ld;
  hf = hd & 0x800fffff;  
  hf |= 0x3fe00000;

  INSERT_WORDS (f, hf, lf);

  return (f);
}

#endif /* _DOUBLE_IS_32BITS */
