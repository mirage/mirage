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
#ifndef _ROUNDF_H_
#define _ROUNDF_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* Round the input to the nearest integer, rounding halfway
 * cases away from zero.
 */
static __inline float _roundf(float x)
{
  vec_int4 exp;
  vec_uint4 or_mask, and_mask, mask, addend;
  vec_float4 in, out;

  in = spu_promote(x, 0);

  /* Add 0.5 (fixed precision to eliminate rounding issues)
   */
  exp = spu_sub(125, spu_and(spu_rlmask((vec_int4)in, -23), 0xFF));

  addend = spu_and(spu_rlmask(VEC_SPLAT_U32(0x1000000), exp),
                   spu_cmpgt((vec_uint4)exp, -31));

  in = (vec_float4)spu_add((vec_uint4)in, addend);

  /* Truncate the result.
   */
  exp = spu_sub(127, spu_and(spu_rlmask((vec_int4)in, -23), 0xFF));

  or_mask = spu_cmpgt(exp, 0);
  and_mask = spu_rlmask(VEC_SPLAT_U32(0x7FFFFF), exp);

  mask = spu_or(spu_and(and_mask, spu_cmpgt(exp, -31)), or_mask);

  out = spu_andc(in, (vec_float4)(mask));

  return (spu_extract(out, 0));
}
#endif /* _ROUNDF_H_ */
