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

#ifndef _CBRT_H_
#define _CBRT_H_	1

#include <spu_intrinsics.h>
#include "headers/vec_literal.h"

extern double cbrt_factors[5];

/* Compute the cube root of x to double precision.
 */

static __inline double _cbrt(double x)
{
  vec_int4 exp, bias;
  vec_uint4 e_div_3, e_mod_3;
  vec_float4 bf, inv_bf;
  vec_float4 onef = VEC_SPLAT_F32(1.0f);
  vec_ullong2 mask;
  vec_ullong2 mant_mask = VEC_SPLAT_U64(0xFFFFFFFFFFFFFULL);
  vec_double2 one = VEC_SPLAT_F64(1.0);
  vec_double2 two = VEC_SPLAT_F64(2.0);
  vec_double2 half = VEC_SPLAT_F64(0.5);
  /* Polynomial coefficients */
  vec_double2 c0 = VEC_SPLAT_F64(0.354895765043919860);
  vec_double2 c1 = VEC_SPLAT_F64(1.50819193781584896);
  vec_double2 c2 = VEC_SPLAT_F64(-2.11499494167371287);
  vec_double2 c3 = VEC_SPLAT_F64(2.44693122563534430);
  vec_double2 c4 = VEC_SPLAT_F64(-1.83469277483613086);
  vec_double2 c5 = VEC_SPLAT_F64(0.784932344976639262);
  vec_double2 c6 = VEC_SPLAT_F64(0.145263899385486377);
  vec_double2 in, out, mant, u, u3, ym, a, b, factor, inv_b;

  in = spu_promote(x, 0);

  /* Normalize the mantissa (fraction part) into the range [0.5, 1.0) and
   * extract the exponent.
   */
  mant = spu_sel(half, in, mant_mask);
  exp = spu_and(spu_rlmask((vec_int4)in, -20), 0x7FF);

  /* Generate mask used to zero result if the exponent is zero (ie, <in> is
   * either zero or a denorm
   */
  mask = (vec_ullong2)spu_cmpeq(exp, 0);
  mask = spu_shuffle(mask, mask, VEC_LITERAL(vec_uchar16, 0,1,2,3,0,1,2,3,8,9,10,11,8,9,10,11));
  exp = spu_add(exp, -1022);

  u = spu_madd(mant, spu_madd(mant, spu_madd(mant, spu_madd(mant, spu_madd(mant, spu_nmsub(mant, c6, c5), c4), c3), c2), c1), c0);
  u3 = spu_mul(spu_mul(u, u), u);

  /* Compute: e_div_3 = exp/3
   *
   * Fetch:   factor = factor[2+exp%3]
   *
   * The factors array contains 5 values: 2^(-2/3), 2^(-1/3), 2^0, 2^(1/3),
   *                                      2^(2/3),  2^1.
   * The fetch is done using shuffle bytes so that is can easily be extended
   * to support SIMD compution.
   */
  bias = spu_rlmask(spu_rlmaska(exp, -15), -16);
  e_div_3 = (vec_uint4)spu_rlmaska(spu_madd((vec_short8)exp, VEC_SPLAT_S16(0x5556), bias), -16);

  e_mod_3 = (vec_uint4)spu_sub((vec_int4)(exp), spu_mulo((vec_short8)e_div_3, VEC_SPLAT_S16(3)));

  factor = spu_promote(cbrt_factors[2+spu_extract(e_mod_3, 0)], 0);

  /* Compute the estimated mantissa cube root (ym) equals:
   *       ym = (u * factor * (2.0 * mant + u3)) / (2.0 * u3 + mant);
   */
  a = spu_mul(spu_mul(factor, u), spu_madd(two, mant, u3));
  b = spu_madd(two, u3, mant);

  bf = spu_roundtf(b);
  inv_bf = spu_re(bf);
  inv_bf = spu_madd(spu_nmsub(bf, inv_bf, onef), inv_bf, inv_bf);

  inv_b = spu_extend(inv_bf);
  inv_b = spu_madd(spu_nmsub(b, inv_b, one), inv_b, inv_b);

  ym = spu_mul(a, inv_b);
  ym = spu_madd(spu_nmsub(b, ym, a), inv_b, ym);

  /* Merge sign, computed exponent, and computed mantissa.
   */
  exp = spu_rl(spu_add((vec_int4)e_div_3, 1023), 20);
  exp = spu_andc(exp, (vec_int4)mant_mask);
  out = spu_sel((vec_double2)exp, in, VEC_SPLAT_U64(0x8000000000000000ULL));
  out = spu_mul(out, ym);

  out = spu_andc(out, (vec_double2)mask);

  return (spu_extract(out, 0));
}

#endif /* _CBRT_H_ */
