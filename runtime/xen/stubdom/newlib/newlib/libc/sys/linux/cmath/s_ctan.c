/* Complex tangent function for double.
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
__ctan (__complex__ double x)
{
  __complex__ double res;

  if (!isfinite (__real__ x) || !isfinite (__imag__ x))
    {
      if (__isinf (__imag__ x))
	{
	  __real__ res = __copysign (0.0, __real__ x);
	  __imag__ res = __copysign (1.0, __imag__ x);
	}
      else if (__real__ x == 0.0)
	{
	  res = x;
	}
      else
	{
	  __real__ res = __nan ("");
	  __imag__ res = __nan ("");

#ifdef FE_INVALID
	  if (__isinf (__real__ x))
	    feraiseexcept (FE_INVALID);
#endif
	}
    }
  else
    {
      double sin2rx, cos2rx;
      double den;

      __sincos (2.0 * __real__ x, &sin2rx, &cos2rx);

      den = cos2rx + __ieee754_cosh (2.0 * __imag__ x);

      __real__ res = sin2rx / den;
      __imag__ res = __ieee754_sinh (2.0 * __imag__ x) / den;
    }

  return res;
}
weak_alias (__ctan, ctan)
#ifdef NO_LONG_DOUBLE
strong_alias (__ctan, __ctanl)
weak_alias (__ctan, ctanl)
#endif
