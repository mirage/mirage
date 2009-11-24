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
#ifndef _SCALBN_H_
#define _SCALBN_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* scalbn computes x * 2^exp. This function variant computes the result
 * and handles overflow, underflow, and denorms by breaking the problem
 * into:
 *      exp = MAX(exp, -2044)
 *      exp = MIN(exp,  2046)
 *      e1 = exp / 2
 *      e2 = exp - e1;
 *      x * 2^e1 * 2^e2
 */
static __inline double _scalbn(double x, int exp)
{
  vec_int4 e, e1, e2;
  vec_int4 min = VEC_SPLAT_S32(-2044);
  vec_int4 max = VEC_SPLAT_S32(2046);
  vec_uint4 cmp_min, cmp_max;
  vec_uint4 shift = VEC_LITERAL(vec_uint4, 20, 32, 20, 32);
  vec_double2 f1, f2;
  vec_double2 in, out;

  in = spu_promote(x, 0);
  e = spu_promote(exp, 0);

  /* Clamp the specified exponent to the range -2044 to 2046.
   */
  cmp_min = spu_cmpgt(e, min);
  cmp_max = spu_cmpgt(e, max);
  e = spu_sel(min, e, cmp_min);
  e = spu_sel(e, max, cmp_max);

  /* Generate the factors f1 = 2^e1 and f2 = 2^e2
   */
  e1 = spu_rlmaska(e, -1);
  e2 = spu_sub(e, e1);

  f1 = (vec_double2)spu_sl(spu_add(e1, 1023), shift);
  f2 = (vec_double2)spu_sl(spu_add(e2, 1023), shift);

  /* Compute the product x * 2^e1 * 2^e2
   */
  out = spu_mul(spu_mul(in, f1), f2);

  return (spu_extract(out, 0));
}
#endif /* _SCALBN_H_ */
