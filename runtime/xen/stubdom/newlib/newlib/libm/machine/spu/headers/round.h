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
#ifndef _ROUND_H_
#define _ROUND_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* Round the input to the nearest integer, rounding halfway
 * cases away from zero.
 */
static __inline double _round(double x)
{
  vec_uchar16 splat_hi = VEC_LITERAL(vec_uchar16, 0,1,2,3,0,1,2,3, 8,9,10,11, 8,9,10,11);
  vec_int4 exp, shift;
  vec_uint4 sign = VEC_LITERAL(vec_uint4, 0x80000000, 0, 0x80000000, 0);
  vec_uint4 or_mask, and_mask, mask, addend;
  vec_double2 in, in_hi, out;

  in = spu_promote(x, 0);

  /* Add 0.5 (fixed precision to eliminate rounding issues)
   */
  in_hi = spu_shuffle(in, in, splat_hi);
  exp = spu_and(spu_rlmask((vec_int4)in_hi, -20), 0x7FF);

  shift = spu_sub(VEC_LITERAL(vec_int4, 1022, 1043, 1022, 1043), exp);

  addend = spu_and(spu_rlmask(VEC_LITERAL(vec_uint4, 0x100000, 0x80000000,
                                          0x100000, 0x80000000), shift),
                   spu_cmpgt((vec_uint4)spu_add(shift, -1), -33));

  in = (vec_double2)spu_addx((vec_uint4)in, addend,
                             spu_rlqwbyte(spu_genc((vec_uint4)in, addend), 4));

  /* Truncate the result.
   */
  in_hi = spu_shuffle(in, in, splat_hi);
  exp = spu_and(spu_rlmask((vec_int4)in_hi, -20), 0x7FF);

  shift = spu_sub(VEC_LITERAL(vec_int4, 1023, 1043, 1023, 1043), exp);
  or_mask = spu_andc(spu_cmpgt(shift, 0), sign);


  and_mask = spu_rlmask(VEC_LITERAL(vec_uint4, 0xFFFFF, -1, 0xFFFFF, -1),
                        shift);
  mask = spu_or(spu_and(and_mask, spu_cmpgt(shift, -31)), or_mask);

  /* Apply the mask and return the result.
   */
  out = spu_andc(in, (vec_double2)(mask));

  return (spu_extract(out, 0));
}
#endif /* _ROUND_H_ */
