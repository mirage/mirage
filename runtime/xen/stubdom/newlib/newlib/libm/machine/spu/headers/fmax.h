/*
  (C) Copyright 2001,2006,
  International Business Machines Corporation,
  Sony Computer Entertainment, Incorporated,
  Toshiba Corporation,

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
    * Neither the names of the copyright holders nor the names of their
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef _FMAX_H_
#define _FMAX_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* Return the maximum numeric value of their arguments. If one argument
 * is a NaN, fmax returns the other value.  If both are NaNs, then a NaN
 * is returned.
 *
 * Notes:
 * 1) Double precision denorms equate to zero so two denorms compare
 *    equal thereby making the following true for two denorm inputs
 *    fmax(a, b) != fmax(b, a);
 */
static __inline double _fmax(double x, double y)
{
  vec_uint4 nan_x, selector, abs_x, gt, eq;
  vec_uint4 sign = VEC_LITERAL(vec_uint4, 0x80000000, 0, 0x80000000, 0);
  vec_uint4 infinity = VEC_LITERAL(vec_uint4, 0x7FF00000, 0, 0x7FF00000, 0);
  vec_double2 vx, vy, diff, max;

  vx = spu_promote(x, 0);
  vy = spu_promote(y, 0);

  /* If x is a NaN, then select y as max
   */
  abs_x = spu_andc((vec_uint4)vx, sign);
  gt = spu_cmpgt(abs_x, infinity);
  eq = spu_cmpeq(abs_x, infinity);

  nan_x = spu_or(gt, spu_and(eq, spu_rlqwbyte(gt, 4)));

  diff = spu_sub(vx, vy);
  selector = spu_orc(nan_x, spu_cmpgt((vec_int4)diff, -1));
  selector = spu_maskw(spu_extract(selector, 0));

  max = spu_sel(vx, vy, (vec_ullong2)selector);

  return (spu_extract(max, 0));
}

#endif /* _FMAX_H_ */
