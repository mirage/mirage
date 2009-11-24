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
#ifndef _CBRTF_H_
#define _CBRTF_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

extern double cbrt_factors[5];

/* Compute the cube root of the floating point input x.
 */

static __inline float _cbrtf(float x)
{
  vec_int4 exp, bias;
  vec_uint4 mask, e_div_3, e_mod_3;
  vec_uint4 mant_mask = VEC_SPLAT_U32(0x7FFFFF);
  vec_float4 in;
  vec_float4 half = VEC_SPLAT_F32(0.5f);
  vec_float4 onef = VEC_SPLAT_F32(1.0f);
  vec_float4 out, mant, ym, bf, inv_bf;
  vec_double2 two = VEC_SPLAT_F64(2.0);
  /* Polynomial coefficients */
  vec_double2 c2 = VEC_SPLAT_F64(0.191502161678719066);
  vec_double2 c1 = VEC_SPLAT_F64(0.697570460207922770);
  vec_double2 c0 = VEC_SPLAT_F64(0.492659620528969547);
  vec_double2 a0, b0, inv_b0, ym0;
  vec_double2 mant0, u0, u0_3, factor0;

  in = spu_promote(x, 0);

  /* Normalize the mantissa (fraction part) into the range [0.5, 1.0) and
   * extract the exponent.
   */
  mant = spu_sel(half, in, mant_mask);
  exp = spu_and(spu_rlmask((vec_int4)in, -23), 0xFF);

  /* Generate mask used to zero result if the exponent is zero (ie, in is either
   * zero or a denorm
   */
  mask = spu_cmpeq(exp, 0);
  exp = spu_add(exp, -126);

  mant0 = spu_extend(mant);

  u0 = spu_madd(mant0, spu_nmsub(mant0, c2, c1), c0);
  u0_3 = spu_mul(spu_mul(u0, u0), u0);

  /* Compute: e_div_3 = exp/3
   *
   * Fetch:   factor = factor[2+exp%3]
   *
   * The factors array contains 5 values: 2^(-2/3), 2^(-1/3), 2^0, 2^(1/3), 2^(2/3), 2^1.
   */
  bias = spu_rlmask(spu_rlmaska(exp, -15), -16);
  e_div_3 = (vec_uint4)spu_rlmaska(spu_madd((vec_short8)exp, VEC_SPLAT_S16(0x5556), bias), -16);

  e_mod_3 = (vec_uint4)spu_sub((vec_int4)(exp), spu_mulo((vec_short8)e_div_3, VEC_SPLAT_S16(3)));

  e_mod_3 = spu_add(e_mod_3, 2);

  factor0 = spu_promote(cbrt_factors[spu_extract(e_mod_3, 0)], 0);

  /* Compute the estimated mantissa cube root (ym) equals:
   *       ym = (u * factor * (2.0 * mant + u3)) / (2.0 * u3 + mant);
   */
  a0 = spu_mul(spu_mul(factor0, u0), spu_madd(two, mant0, u0_3));
  b0 = spu_madd(two, u0_3, mant0);

  bf = spu_roundtf(b0);

  inv_bf = spu_re(bf);
  inv_bf = spu_madd(spu_nmsub(bf, inv_bf, onef), inv_bf, inv_bf);

  inv_b0 = spu_extend(inv_bf);

  ym0 = spu_mul(a0, inv_b0);
  ym0 = spu_madd(spu_nmsub(b0, ym0, a0), inv_b0, ym0);

  ym = spu_roundtf(ym0);

  /* Merge sign, computed exponent, and computed mantissa.
   */
  exp = spu_rl(spu_add((vec_int4)e_div_3, 127), 23);
  out = spu_sel((vec_float4)exp, in, VEC_SPLAT_U32(0x80000000));
  out = spu_mul(out, ym);

  out = spu_andc(out, (vec_float4)mask);

  return (spu_extract(out, 0));
}

#endif /* _CBRTF_H_ */
