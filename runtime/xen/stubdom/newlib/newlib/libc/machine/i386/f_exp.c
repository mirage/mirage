/*
 * ====================================================
 * Copyright (C) 1998,2002 by Red Hat Inc. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

#if !defined(_SOFT_FLOAT)

/*
Fast version of exp using Intel float instructions.

   double _f_exp (double x);

Function computes e ** x.  The following special cases exist:
   1. if x is 0.0 ==> return 1.0
   2. if x is infinity ==> return infinity
   3. if x is -infinity ==> return 0.0
   4. if x is NaN ==> return x
There is no error checking or setting of errno.
*/


#include <math.h>
#include <ieeefp.h>
#include "f_math.h"

double _f_exp (double x)
{
   if (check_finite(x))
     {
       double result;
       asm ("fldl2e; fmulp; fld %%st; frndint; fsub %%st,%%st(1); fxch;" \
          "fchs; f2xm1; fld1; faddp; fxch; fld1; fscale; fstp %%st(1); fmulp" :
          "=t"(result) : "0"(x));
       return result;
     }
   else if (x == -infinity())
     return 0.0;

   return x;
}

#endif
