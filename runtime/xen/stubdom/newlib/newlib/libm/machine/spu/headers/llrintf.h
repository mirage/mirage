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
#ifndef _LLRINTF_H_
#define _LLRINTF_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

static __inline long long int _llrintf(float x)
{
  int shift;
  vec_int4 exp;
  vec_uint4 mant, sign, borrow;
  vec_float4 in;

  in = spu_promote(x, 0);

  /* Place mantissa bits (including implied most signficant
   * bit) into the most significant bits of element 3. Elements
   * 0, 1, and 2 are zeroed.
   */
  mant = spu_sel(spu_rlmaskqwbyte((vec_uint4)in, -11),
                 VEC_SPLAT_U32(0x80000000),
                 VEC_LITERAL(vec_uint4, 0,0,0xFF,0x800000FF));

  /* Determine how many bits to shift the mantissa to correctly
   * align it into long long element 0.
   */
  exp = spu_and(spu_rlmask((vec_int4)in, -23), 0xFF);
  shift = spu_extract(spu_add(exp, -94), 0);

  /* Algn mantissa bits
   */
  mant = spu_slqwbytebc(spu_slqw(mant, shift), shift);

  /* Compute the two's complement of the mantissa if the
   * input is negative.
   */
  sign = spu_maskw(spu_extract(spu_rlmaska((vec_int4)in, -31), 0));

  mant = spu_xor(mant, sign);
  borrow = spu_genb(mant, sign);
  borrow = spu_shuffle(borrow, borrow,
                       VEC_LITERAL(vec_uchar16, 4,5,6,7, 192,192,192,192,
                                   4,5,6,7, 192,192,192,192));
  mant = spu_subx(mant, sign, borrow);

  return (spu_extract((vec_llong2)(mant), 0));
}
#endif /* _LLRINTF_H_ */
