/* Complex tangent function for float.
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


__complex__ float
__ctanf (__complex__ float x)
{
  __complex__ float res;

  if (!isfinite (__real__ x) || !isfinite (__imag__ x))
    {
      if (__isinff (__imag__ x))
	{
	  __real__ res = __copysignf (0.0, __real__ x);
	  __imag__ res = __copysignf (1.0, __imag__ x);
	}
      else if (__real__ x == 0.0)
	{
	  res = x;
	}
      else
	{
	  __real__ res = __nanf ("");
	  __imag__ res = __nanf ("");

#ifdef FE_INVALID
	  if (__isinff (__real__ x))
	    feraiseexcept (FE_INVALID);
#endif
	}
    }
  else
    {
      float sin2rx, cos2rx;
      float den;

      __sincosf (2.0 * __real__ x, &sin2rx, &cos2rx);

      den = cos2rx + __ieee754_coshf (2.0 * __imag__ x);

      __real__ res = sin2rx / den;
      __imag__ res = __ieee754_sinhf (2.0 * __imag__ x) / den;
    }

  return res;
}
weak_alias (__ctanf, ctanf)
