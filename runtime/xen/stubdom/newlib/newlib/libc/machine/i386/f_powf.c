/*
 * ====================================================
 * Copyright (C) 1998, 2002 by Red Hat Inc. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

#if !defined(_SOFT_FLOAT)

/*
Fast version of pow using Intel float instructions.

   float _f_powf (float x, float y);

Function calculates x to power of y.
The function optimizes the case where x is >0.0 and y is finite.
In such a case, there is no error checking or setting of errno.
All other cases defer to normal powf() function which will
set errno as normal.
*/

#include <math.h>
#include <ieeefp.h>
#include "f_math.h"

float _f_powf (float x, float y)
{
  /* following sequence handles the majority of cases for pow() */
  if (x > 0.0 && check_finitef(y))
    {
      float result;
      /* calculate x ** y as 2 ** (y log2(x)).  On Intel, can only
         raise 2 to an integer or a small fraction, thus, we have
         to perform two steps 2**integer portion * 2**fraction. */
      asm ("flds 8(%%ebp); fyl2x; fld %%st; frndint; fsub %%st,%%st(1);" \
           "fxch; fchs; f2xm1; fld1; faddp; fxch; fld1; fscale; fstp %%st(1);"\
           "fmulp" : "=t" (result) : "0" (y));
      return result;
    }
  else /* all other strange cases, defer to normal pow() */
    return powf (x,y);
}

#endif
