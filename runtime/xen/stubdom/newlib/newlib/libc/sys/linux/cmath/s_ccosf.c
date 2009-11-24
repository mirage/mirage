/* Return cosine of complex float value.
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
__ccosf (__complex__ float x)
{
  __complex__ float res;

  if (!isfinite (__real__ x) || __isnanf (__imag__ x))
    {
      if (__real__ x == 0.0 || __imag__ x == 0.0)
	{
	  __real__ res = __nanf ("");
	  __imag__ res = 0.0;

#ifdef FE_INVALID
	  if (__isinff (__real__ x))
	    feraiseexcept (FE_INVALID);
#endif
	}
      else if (__isinff (__imag__ x))
	{
	  __real__ res = HUGE_VALF;
	  __imag__ res = __nanf ("");

#ifdef FE_INVALID
	  if (__isinff (__real__ x))
	    feraiseexcept (FE_INVALID);
#endif
	}
      else
	{
	  __real__ res = __nanf ("");
	  __imag__ res = __nanf ("");

#ifdef FE_INVALID
	  if (isfinite (__imag__ x))
	    feraiseexcept (FE_INVALID);
#endif
	}
    }
  else
    {
      __complex__ float y;

      __real__ y = -__imag__ x;
      __imag__ y = __real__ x;

      res = __ccoshf (y);
    }

  return res;
}
weak_alias (__ccosf, ccosf)
