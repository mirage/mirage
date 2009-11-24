/* Complex sine function for double.
   Copyright (C) 1997 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1997.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include <complex.h>
#include <fenv.h>
#include <math.h>

#include "math_private.h"


__complex__ double
__csin (__complex__ double x)
{
  __complex__ double retval;
  int negate = signbit (__real__ x);
  int rcls = fpclassify (__real__ x);
  int icls = fpclassify (__imag__ x);

  __real__ x = fabs (__real__ x);

  if (icls >= FP_ZERO)
    {
      /* Imaginary part is finite.  */
      if (rcls >= FP_ZERO)
	{
	  /* Real part is finite.  */
	  double sinh_val = __ieee754_sinh (__imag__ x);
	  double cosh_val = __ieee754_cosh (__imag__ x);
	  double sinix, cosix;

	  __sincos (__real__ x, &sinix, &cosix);

	  __real__ retval = cosh_val * sinix;
	  __imag__ retval = sinh_val * cosix;

	  if (negate)
	    __real__ retval = -__real__ retval;
	}
      else
	{
	  if (icls == FP_ZERO)
	    {
	      /* Imaginary part is 0.0.  */
	      __real__ retval = __nan ("");
	      __imag__ retval = __imag__ x;

#ifdef FE_INVALID
	      if (rcls == FP_INFINITE)
		feraiseexcept (FE_INVALID);
#endif
	    }
	  else
	    {
	      __real__ retval = __nan ("");
	      __imag__ retval = __nan ("");

#ifdef FE_INVALID
	      feraiseexcept (FE_INVALID);
#endif
	    }
	}
    }
  else if (icls == FP_INFINITE)
    {
      /* Imaginary part is infinite.  */
      if (rcls == FP_ZERO)
	{
	  /* Real part is 0.0.  */
	  __real__ retval = __copysign (0.0, negate ? -1.0 : 1.0);
	  __imag__ retval = __imag__ x;
	}
      else if (rcls > FP_ZERO)
	{
	  /* Real part is finite.  */
	  double sinix, cosix;

	  __sincos (__real__ x, &sinix, &cosix);

	  __real__ retval = __copysign (HUGE_VAL, sinix);
	  __imag__ retval = __copysign (HUGE_VAL, cosix);

	  if (negate)
	    __real__ retval = -__real__ retval;
	  if (signbit (__imag__ x))
	    __imag__ retval = -__imag__ retval;
	}
      else
	{
	  /* The addition raises the invalid exception.  */
	  __real__ retval = __nan ("");
	  __imag__ retval = HUGE_VAL;

#ifdef FE_INVALID
	  if (rcls == FP_INFINITE)
	    feraiseexcept (FE_INVALID);
#endif
	}
    }
  else
    {
      if (rcls == FP_ZERO)
	__real__ retval = __copysign (0.0, negate ? -1.0 : 1.0);
      else
	__real__ retval = __nan ("");
      __imag__ retval = __nan ("");
    }

  return retval;
}
weak_alias (__csin, csin)
#ifdef NO_LONG_DOUBLE
strong_alias (__csin, __csinl)
weak_alias (__csin, csinl)
#endif
