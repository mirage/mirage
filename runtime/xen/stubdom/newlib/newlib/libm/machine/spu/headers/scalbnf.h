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
#ifndef _SCALBNF_H_
#define _SCALBNF_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

/* scalbnf computes x * 2^exp. This function is computed without
 * the assistence of any floating point operations and as such does
 * not set any floating point exceptions.
 */
static __inline float _scalbnf(float x, int exp)
{
  vec_int4 x_exp;
  vec_uint4 zero, overflow;
  vec_uint4 exp_mask = VEC_SPLAT_U32(0x7F800000);
  vec_float4 in, out;

  in = spu_promote(x, 0);

  /* Extract exponent from x. If the exponent is 0, then
   * x is either 0 or a denorm and x*2^exp is a zero.
   */
  x_exp = spu_and(spu_rlmask((vec_int4)in, -23), 0xFF);

  zero = spu_cmpeq(x_exp, 0);

  /* Compute the expected exponent and determine if the
   * result is within range.
   */
  x_exp = spu_add(spu_promote(exp, 0), x_exp);

  zero = spu_orc(zero, spu_cmpgt(x_exp, 0));

  overflow = spu_rlmask(spu_cmpgt(x_exp, 255), -1);

  /* Merge the expect exponent with x's mantissa. Zero the
   * result if underflow and force to max if overflow.
   */
  out = spu_sel(in, (vec_float4)spu_rl(x_exp, 23), exp_mask);
  out = spu_andc(out, (vec_float4)zero);
  out = spu_or(out, (vec_float4)overflow);

  return (spu_extract(out, 0));
}
#endif /* _SCALBNF_H_ */
