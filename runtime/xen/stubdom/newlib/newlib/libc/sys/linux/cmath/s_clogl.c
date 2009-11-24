/* Compute complex natural logarithm.
   Copyright (C) 1997, 1998 Free Software Foundation, Inc.
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


__complex__ long double
__clogl (__complex__ long double x)
{
  __complex__ long double result;
  int rcls = fpclassify (__real__ x);
  int icls = fpclassify (__imag__ x);

  if (rcls == FP_ZERO && icls == FP_ZERO)
    {
      /* Real and imaginary part are 0.0.  */
      __imag__ result = signbit (__real__ x) ? M_PIl : 0.0;
      __imag__ result = __copysignl (__imag__ result, __imag__ x);
      /* Yes, the following line raises an exception.  */
      __real__ result = -1.0 / fabsl (__real__ x);
    }
  else if (rcls != FP_NAN && icls != FP_NAN)
    {
      /* Neither real nor imaginary part is NaN.  */
      __real__ result = __ieee754_logl (__ieee754_hypotl (__real__ x,
							  __imag__ x));
      __imag__ result = __ieee754_atan2l (__imag__ x, __real__ x);
    }
  else
    {
      __imag__ result = __nanl ("");
      if (rcls == FP_INFINITE || icls == FP_INFINITE)
	/* Real or imaginary part is infinite.  */
	__real__ result = HUGE_VALL;
      else
	__real__ result = __nanl ("");
    }

  return result;
}
weak_alias (__clogl, clogl)
