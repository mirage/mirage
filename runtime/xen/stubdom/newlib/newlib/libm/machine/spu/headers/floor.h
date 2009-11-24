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
#ifndef _FLOOR_H_
#define _FLOOR_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* Round the input downwards to the nearest integer.
 */
static __inline double _floor(double x)
{
  vec_uchar16 swap_words = VEC_LITERAL(vec_uchar16, 4,5,6,7, 0,1,2,3, 12,13,14,15, 8,9,10,11);
  vec_uchar16 splat_hi = VEC_LITERAL(vec_uchar16, 0,1,2,3,0,1,2,3, 8,9,10,11, 8,9,10,11);
  vec_uint4 one = VEC_LITERAL(vec_uint4, 0, 1, 0, 1);
  vec_int4 exp, shift;
  vec_uint4 mask, mask_1, frac_mask, addend, insert, pos, equal0;
  vec_ullong2 sign = VEC_SPLAT_U64(0x8000000000000000ULL);
  vec_double2 in, in_hi, out;
  vec_double2 minus_one = VEC_SPLAT_F64(-1.0);

  in = spu_promote(x, 0);

  /* This function generates the following component
   * based upon the inputs.
   *
   *   mask = bits of the input that need to be replaced.
   *   insert = value of the bits that need to be replaced
   *   addend = value to be added to perform function.
   *
   * These are applied as follows:.
   *
   *   out = ((in & mask) | insert) + addend
   */
  in_hi = spu_shuffle(in, in, splat_hi);
  pos = spu_cmpgt((vec_int4)in_hi, -1);
  exp = spu_and(spu_rlmask((vec_int4)in_hi, -20), 0x7FF);
  shift = spu_sub(VEC_LITERAL(vec_int4, 1023, 1043, 1023, 1043), exp);

  /* clamp shift to the range 0 to -31.
   */
  shift = spu_sel(VEC_SPLAT_S32(-32), spu_andc(shift, (vec_int4)spu_cmpgt(shift, 0)), spu_cmpgt(shift, -32));

  frac_mask = spu_rlmask(VEC_LITERAL(vec_uint4, 0xFFFFF, -1, 0xFFFFF, -1), shift);
  mask = spu_orc(frac_mask, spu_cmpgt(exp, 0x3FE));

  /* addend = ((in & mask) && (in >= 0)) ? mask+1 : 0
   */
  mask_1 = spu_addx(mask, one, spu_rlqwbyte(spu_genc(mask, one), 4));

  equal0 = spu_cmpeq(spu_and((vec_uint4)in, mask), 0);
  addend = spu_andc(spu_andc(mask_1, pos),
                    spu_and(equal0, spu_shuffle(equal0, equal0, swap_words)));

  insert = spu_andc(spu_andc((vec_uint4)minus_one, pos),
                    spu_cmpgt((vec_uint4)spu_add(exp, -1), 1022));

  in = spu_sel(in, (vec_double2)insert, spu_andc((vec_ullong2)mask, sign));
  out = (vec_double2)spu_addx((vec_uint4)in, addend,
                              spu_rlqwbyte(spu_genc((vec_uint4)in, addend), 4));

  return (spu_extract(out, 0));
}
#endif /* _FLOOR_H_ */
