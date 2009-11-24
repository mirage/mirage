/* Return arc hyperbole cosine for float value.
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
#include <math.h>
#include "math_private.h"

__complex__ float
__cacoshf (__complex__ float x)
{
  __complex__ float res;
  int rcls = fpclassify (__real__ x);
  int icls = fpclassify (__imag__ x);

  if (rcls <= FP_INFINITE || icls <= FP_INFINITE)
    {
      if (icls == FP_INFINITE)
	{
	  __real__ res = HUGE_VALF;

	  if (rcls == FP_NAN)
	    __imag__ res = __nanf ("");
	  else
	    __imag__ res = __copysignf ((rcls == FP_INFINITE
					 ? (__real__ x < 0.0
					    ? M_PI - M_PI_4 : M_PI_4)
					 : M_PI_2), __imag__ x);
	}
      else if (rcls == FP_INFINITE)
	{
	  __real__ res = HUGE_VALF;

	  if (icls >= FP_ZERO)
	    __imag__ res = __copysignf (signbit (__real__ x) ? M_PI : 0.0,
					__imag__ x);
	  else
	    __imag__ res = __nanf ("");
	}
      else
	{
	  __real__ res = __nanf ("");
	  __imag__ res = __nanf ("");
	}
    }
  else if (rcls == FP_ZERO && icls == FP_ZERO)
    {
      __real__ res = 0.0;
      __imag__ res = __copysignf (M_PI_2, __imag__ x);
    }
  else
    {
#if 1
      __complex__ float y;

      __real__ y = (__real__ x - __imag__ x) * (__real__ x + __imag__ x) - 1.0;
      __imag__ y = 2.0 * __real__ x * __imag__ x;

      y = __csqrtf (y);

      __real__ y += __real__ x;
      __imag__ y += __imag__ x;

      res = __clogf (y);
#else
      float re2 = __real__ x * __real__ x;
      float im2 = __imag__ x * __imag__ x;
      float sq = re2 - im2 - 1.0;
      float ro = __ieee754_sqrtf (sq * sq + 4 * re2 * im2);
      float a = __ieee754_sqrtf ((sq + ro) / 2.0);
      float b = __ieee754_sqrtf ((-sq + ro) / 2.0);

      __real__ res = 0.5 * __ieee754_logf (re2 + __real__ x * 2 * a
					   + im2 + __imag__ x * 2 * b
					   + ro);
      __imag__ res = __ieee754_atan2f (__imag__ x + b, __real__ x + a);
#endif
    }

  return res;
}
weak_alias (__cacoshf, cacoshf)
